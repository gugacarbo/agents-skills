#!/usr/bin/env node

import { randomUUID } from "node:crypto";
import { promises as fs } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const skillDirectory = path.dirname(
	path.dirname(fileURLToPath(import.meta.url)),
);
const templatesDirectory = path.join(skillDirectory, "templates");
const templatesRealDirectory = await fs.realpath(templatesDirectory);
const supportedActions = new Set(["list", "plan", "apply"]);
const actionOptions = {
	list: new Set(),
	plan: new Set(["template", "target", "name", "variant", "optional"]),
	apply: new Set([
		"template",
		"target",
		"name",
		"variant",
		"optional",
		"approve",
	]),
};

class ProjectInitError extends Error {
	constructor(message, details = {}, exitCode = 1) {
		super(message);
		this.details = details;
		this.exitCode = exitCode;
	}
}

function fail(message, details = {}, exitCode = 1) {
	throw new ProjectInitError(message, details, exitCode);
}

function parseArgs(argv) {
	const [action, ...rest] = argv;
	if (!supportedActions.has(action)) {
		fail("Expected one of: list, plan, apply", { received: action ?? null });
	}
	const options = { action, optional: [], approve: [] };
	const seen = new Set();
	for (let index = 0; index < rest.length; index += 1) {
		const argument = rest[index];
		if (!argument.startsWith("--")) fail(`Unexpected argument: ${argument}`);
		const key = argument.slice(2);
		if (!actionOptions[action].has(key)) {
			fail(`Unknown option for ${action}: --${key}`, {
				allowedOptions: [...actionOptions[action]].map((item) => `--${item}`),
			});
		}
		if (seen.has(key)) fail(`Duplicate option: --${key}`);
		seen.add(key);
		const value = rest[index + 1];
		if (!value || value.startsWith("--")) fail(`Missing value for --${key}`);
		if (["optional", "approve"].includes(key)) {
			options[key] = value
				.split(",")
				.map((entry) => entry.trim())
				.filter(Boolean);
		} else {
			options[key] = value;
		}
		index += 1;
	}
	return options;
}

async function pathInfo(filePath) {
	try {
		return await fs.lstat(filePath);
	} catch (error) {
		if (error.code === "ENOENT") return null;
		throw error;
	}
}

async function exists(filePath) {
	return Boolean(await pathInfo(filePath));
}

function isInside(root, candidate) {
	const relative = path.relative(root, candidate);
	return (
		relative === "" ||
		(!relative.startsWith("..") && !path.isAbsolute(relative))
	);
}

async function assertNoSymlinks(absolutePath) {
	const resolved = path.resolve(absolutePath);
	const { root } = path.parse(resolved);
	let current = root;
	const segments = resolved.slice(root.length).split(path.sep).filter(Boolean);
	for (let index = 0; index < segments.length; index += 1) {
		current = path.join(current, segments[index]);
		const info = await pathInfo(current);
		if (!info) break;
		if (info.isSymbolicLink()) {
			fail("Symlinks are not allowed in project-init write paths", {
				path: current,
			});
		}
		if (index < segments.length - 1 && !info.isDirectory()) {
			fail("A write-path ancestor is not a directory", { path: current });
		}
	}
}

async function assertSafeTarget(target) {
	await assertNoSymlinks(target);
	const info = await pathInfo(target);
	if (info && !info.isDirectory()) {
		fail("Target exists but is not a directory", { target });
	}
}

function validateTemplateId(templateId) {
	if (
		typeof templateId !== "string" ||
		!/^_base$|^[a-z0-9]+(?:-[a-z0-9]+)*(?:\/[a-z0-9]+(?:-[a-z0-9]+)*)*$/.test(
			templateId,
		)
	) {
		fail(`Invalid template id: ${String(templateId)}`);
	}
}

function validateOutputTarget(target) {
	if (
		typeof target !== "string" ||
		!target ||
		path.isAbsolute(target) ||
		target.includes("\\")
	) {
		fail(`Invalid output target: ${String(target)}`);
	}
	const segments = target.split("/");
	if (
		segments.some((segment) => !segment || segment === "." || segment === "..")
	) {
		fail(`Invalid output target: ${target}`);
	}
	return segments.join("/");
}

async function safeTemplateSource(manifest, source) {
	if (typeof source !== "string" || !source)
		fail("Template source is required");
	const candidate = path.resolve(manifest.directory, source);
	if (!isInside(templatesDirectory, candidate)) {
		fail(`Source escapes templates directory: ${source}`, {
			template: manifest.id,
		});
	}
	const info = await pathInfo(candidate);
	if (!info?.isFile()) {
		fail(`Missing template source: ${source}`, { template: manifest.id });
	}
	const real = await fs.realpath(candidate);
	if (!isInside(templatesRealDirectory, real)) {
		fail(`Source symlink escapes templates directory: ${source}`, {
			template: manifest.id,
		});
	}
	return real;
}

async function readJson(filePath, label) {
	try {
		return JSON.parse(await fs.readFile(filePath, "utf8"));
	} catch (error) {
		fail(`Invalid JSON in ${label}`, { path: filePath, cause: error.message });
	}
}

async function loadManifest(templateId) {
	validateTemplateId(templateId);
	const manifestPath = path.join(
		templatesDirectory,
		templateId,
		"template.json",
	);
	if (!(await exists(manifestPath))) {
		fail(`Unknown template: ${templateId}`, {
			available: await listTemplates(),
		});
	}
	const realManifestPath = await fs.realpath(manifestPath);
	if (!isInside(templatesRealDirectory, realManifestPath)) {
		fail(`Manifest escapes templates directory: ${templateId}`);
	}
	const manifest = await readJson(realManifestPath, `manifest ${templateId}`);
	if (manifest.id !== templateId)
		fail(`Manifest id mismatch for ${templateId}`);
	return { ...manifest, directory: path.dirname(realManifestPath) };
}

async function listTemplates() {
	const found = [];
	const manifests = new Map();
	async function visit(relative = "") {
		const absolute = path.join(templatesDirectory, relative);
		for (const entry of await fs.readdir(absolute, { withFileTypes: true })) {
			if (
				!entry.isDirectory() ||
				(entry.name.startsWith("_") && entry.name !== "_base")
			) {
				continue;
			}
			const child = path.join(relative, entry.name);
			const manifestPath = path.join(
				templatesDirectory,
				child,
				"template.json",
			);
			if (await exists(manifestPath)) {
				const manifest = await readJson(manifestPath, `manifest ${child}`);
				manifests.set(manifest.id, manifest);
				found.push({
					_manifest: manifest,
					id: manifest.id === "_base" ? "base-only" : manifest.id,
					description: manifest.description,
					variants: Object.keys(manifest.variants ?? {}),
					defaultVariant: manifest.defaultVariant ?? null,
				});
			}
			await visit(child);
		}
	}
	await visit();
	function optionalToolsFor(manifest, visiting = new Set()) {
		if (visiting.has(manifest.id)) return new Map();
		const nextVisiting = new Set(visiting).add(manifest.id);
		const tools = new Map();
		for (const parentId of manifest.extends ?? []) {
			const parent = manifests.get(parentId);
			if (!parent) continue;
			for (const [id, tool] of optionalToolsFor(parent, nextVisiting)) {
				tools.set(id, tool);
			}
		}
		for (const [id, tool] of Object.entries(manifest.optionalTools ?? {})) {
			tools.set(id, tool);
		}
		return tools;
	}
	for (const item of found) {
		const registry = optionalToolsFor(item._manifest);
		item.optionalTools = [...registry].map(([id, { description }]) => ({
			id,
			description,
		}));
		delete item._manifest;
	}
	return found.sort((left, right) => left.id.localeCompare(right.id));
}

async function resolveStack(requestedTemplate) {
	const templateId =
		requestedTemplate === "base-only" ? "_base" : requestedTemplate;
	const stack = [];
	const visiting = new Set();
	async function add(id) {
		if (visiting.has(id)) fail(`Template inheritance cycle at ${id}`);
		if (stack.some((manifest) => manifest.id === id)) return;
		visiting.add(id);
		const manifest = await loadManifest(id);
		for (const parent of manifest.extends ?? []) await add(parent);
		visiting.delete(id);
		stack.push(manifest);
	}
	await add(templateId);
	return stack;
}

function parseMarkdownDocument(markdown) {
	const lines = markdown.replaceAll("\r\n", "\n").split("\n");
	const sections = [];
	let current = null;
	for (const line of lines) {
		if (line.startsWith("## ")) {
			if (current) sections.push(current);
			current = { heading: line.slice(3).trim(), lines: [line] };
		} else if (current) {
			current.lines.push(line);
		}
	}
	if (current) sections.push(current);
	if (!sections.length) fail("Document fragment has no second-level sections");
	return sections.map((section) => ({
		...section,
		content: section.lines.join("\n").trimEnd(),
	}));
}

function renderTemplate(value, variables) {
	return Object.entries(variables).reduce(
		(result, [key, replacement]) =>
			result.replaceAll(`{{${key}}}`, String(replacement)),
		value,
	);
}

function renderDeep(value, variables) {
	if (typeof value === "string") return renderTemplate(value, variables);
	if (Array.isArray(value))
		return value.map((item) => renderDeep(item, variables));
	if (value && typeof value === "object") {
		return Object.fromEntries(
			Object.entries(value).map(([key, item]) => [
				key,
				renderDeep(item, variables),
			]),
		);
	}
	return value;
}

async function composeDocuments(stack, variables) {
	const documents = new Map();
	for (const manifest of stack) {
		for (const [targetValue, source] of Object.entries(
			manifest.documents ?? {},
		)) {
			const target = validateOutputTarget(targetValue);
			const sourcePath = await safeTemplateSource(manifest, source);
			const markdown = renderTemplate(
				await fs.readFile(sourcePath, "utf8"),
				variables,
			);
			const current = documents.get(target) ?? {
				order: [],
				sections: new Map(),
				origins: new Map(),
			};
			for (const section of parseMarkdownDocument(markdown)) {
				if (!current.sections.has(section.heading)) {
					current.order.push(section.heading);
				}
				current.sections.set(section.heading, section.content);
				current.origins.set(section.heading, manifest.id);
			}
			documents.set(target, current);
		}
	}
	return [...documents.entries()].map(([target, document]) => {
		const title =
			target === "AGENTS.md"
				? "# Project conventions"
				: "# Project requirements";
		return {
			target,
			content: Buffer.from(
				`${title}\n\n${document.order
					.map((heading) => document.sections.get(heading))
					.join("\n\n")}\n`,
			),
			mode: 0o644,
			kind: "document",
			origin: Object.fromEntries(
				document.order.map((heading) => [
					heading,
					document.origins.get(heading),
				]),
			),
			source: "generated",
		};
	});
}

function resolvedPackageManager(stack) {
	return (
		[...stack].reverse().find((manifest) => manifest.packageManager)
			?.packageManager ?? null
	);
}

function resolveVariant(stack, requestedVariant) {
	const deepest = stack.at(-1);
	const variants = deepest.variants ?? {};
	if (!Object.keys(variants).length) {
		if (requestedVariant) {
			fail(`Template ${deepest.id} does not accept --variant`);
		}
		return null;
	}
	const variant = requestedVariant ?? deepest.defaultVariant;
	if (!variant || !variants[variant]) {
		fail(`Unknown variant for ${deepest.id}: ${variant ?? "<missing>"}`, {
			availableVariants: Object.keys(variants),
		});
	}
	return { id: variant, ...variants[variant] };
}

function mergeOptionalTools(stack) {
	const tools = new Map();
	for (const manifest of stack) {
		for (const [id, definition] of Object.entries(
			manifest.optionalTools ?? {},
		)) {
			const previous = tools.get(id) ?? {
				id,
				files: [],
				packageJson: {},
				dependencies: [],
				devDependencies: [],
				notes: [],
			};
			tools.set(id, {
				...previous,
				...definition,
				id,
				files: [
					...previous.files,
					...(definition.files ?? []).map((file) => ({ ...file, manifest })),
				],
				packageJson: mergeObjects(
					previous.packageJson,
					definition.packageJson ?? {},
				),
				dependencies: [
					...previous.dependencies,
					...(definition.dependencies ?? []),
				],
				devDependencies: [
					...previous.devDependencies,
					...(definition.devDependencies ?? []),
				],
				notes: [...previous.notes, ...(definition.notes ?? [])],
			});
		}
	}
	return tools;
}

async function collectAssets(stack, selectedTools, toolRegistry, variables) {
	const assets = new Map();
	async function addAsset(file, manifest, kind) {
		const target = validateOutputTarget(file.target);
		if (target === "package.json") {
			fail(
				"package.json must be managed through the semantic package contract",
			);
		}
		const source = await safeTemplateSource(manifest, file.source);
		const info = await fs.stat(source);
		const raw = await fs.readFile(source);
		const isText = !raw.includes(0);
		assets.set(target, {
			target,
			content: isText
				? Buffer.from(renderTemplate(raw.toString("utf8"), variables))
				: raw,
			mode: info.mode & 0o777,
			kind,
			origin: manifest.id,
			source: path.relative(skillDirectory, source).replaceAll(path.sep, "/"),
		});
	}
	for (const manifest of stack) {
		for (const target of manifest.omitTargets ?? []) {
			assets.delete(validateOutputTarget(target));
		}
		for (const file of manifest.files ?? []) {
			await addAsset(file, manifest, "file");
		}
	}
	for (const toolId of selectedTools) {
		for (const file of toolRegistry.get(toolId).files ?? []) {
			await addAsset(file, file.manifest, `optional:${toolId}`);
		}
	}
	return [...assets.values()];
}

function isPlainObject(value) {
	return (
		value !== null &&
		typeof value === "object" &&
		!Array.isArray(value) &&
		Object.getPrototypeOf(value) === Object.prototype
	);
}

function clone(value) {
	return value === undefined ? undefined : structuredClone(value);
}

function mergeObjects(base, overlay) {
	const result = isPlainObject(base) ? clone(base) : {};
	for (const [key, value] of Object.entries(overlay ?? {})) {
		result[key] =
			isPlainObject(value) && isPlainObject(result[key])
				? mergeObjects(result[key], value)
				: clone(value);
	}
	return result;
}

function pointerSegments(pointer) {
	if (!pointer.startsWith("/")) fail(`Invalid JSON pointer: ${pointer}`);
	return pointer
		.slice(1)
		.split("/")
		.map((segment) => segment.replaceAll("~1", "/").replaceAll("~0", "~"));
}

function removePointer(object, pointer) {
	const segments = pointerSegments(pointer);
	let current = object;
	for (const segment of segments.slice(0, -1)) {
		if (!isPlainObject(current?.[segment])) return;
		current = current[segment];
	}
	delete current?.[segments.at(-1)];
}

function removePointerAndPrune(object, pointer) {
	const segments = pointerSegments(pointer);
	const parents = [];
	let current = object;
	for (const segment of segments.slice(0, -1)) {
		if (!isPlainObject(current?.[segment])) return false;
		parents.push([current, segment]);
		current = current[segment];
	}
	const leaf = segments.at(-1);
	if (!Object.hasOwn(current, leaf)) return false;
	delete current[leaf];
	for (const [parent, segment] of parents.reverse()) {
		if (Object.keys(parent[segment]).length > 0) break;
		delete parent[segment];
	}
	return true;
}

function pointerValue(object, pointer) {
	let current = object;
	for (const segment of pointerSegments(pointer)) {
		if (!isPlainObject(current) || !Object.hasOwn(current, segment)) {
			return { found: false, value: undefined };
		}
		current = current[segment];
	}
	return { found: true, value: current };
}

function encodePointerSegment(segment) {
	return segment.replaceAll("~", "~0").replaceAll("/", "~1");
}

function valuesEqual(left, right) {
	return JSON.stringify(left) === JSON.stringify(right);
}

function mergeManagedPackage(existing, desired, removals = []) {
	const result = clone(existing ?? {});
	const changes = [];
	const collisions = [];
	function visit(current, wanted, pointer = "") {
		for (const [key, value] of Object.entries(wanted)) {
			const childPointer = `${pointer}/${encodePointerSegment(key)}`;
			const hasKey = Object.hasOwn(current, key);
			if (isPlainObject(value)) {
				if (!hasKey) current[key] = {};
				if (isPlainObject(current[key])) {
					visit(current[key], value, childPointer);
					continue;
				}
			}
			if (!hasKey) {
				current[key] = clone(value);
				changes.push({
					pointer: childPointer,
					status: "add",
					before: null,
					after: clone(value),
				});
			} else if (!valuesEqual(current[key], value)) {
				changes.push({
					pointer: childPointer,
					status: "replace",
					before: clone(current[key]),
					after: clone(value),
				});
				collisions.push(`package.json#${childPointer}`);
				current[key] = clone(value);
			}
		}
	}
	visit(result, desired);
	for (const pointer of removals) {
		const before = pointerValue(result, pointer);
		if (!before.found) continue;
		removePointerAndPrune(result, pointer);
		changes.push({
			pointer,
			status: "remove",
			before: clone(before.value),
			after: null,
		});
		collisions.push(`package.json#${pointer}`);
	}
	return { result, changes, collisions };
}

function packageFormatting(raw) {
	if (raw === null) return { indent: "\t", eol: "\n", finalNewline: true };
	const eol = raw.includes("\r\n") ? "\r\n" : "\n";
	const indentMatch = raw.match(/\r?\n([ \t]+)"/);
	return {
		indent: indentMatch?.[1] ?? "\t",
		eol,
		finalNewline: raw.endsWith("\n"),
	};
}

function serializePackage(value, formatting) {
	let rendered = JSON.stringify(value, null, formatting.indent);
	if (formatting.eol !== "\n")
		rendered = rendered.replaceAll("\n", formatting.eol);
	if (formatting.finalNewline) rendered += formatting.eol;
	return Buffer.from(rendered);
}

async function loadPackage(target) {
	const packagePath = path.join(target, "package.json");
	const info = await pathInfo(packagePath);
	if (!info) return { value: null, raw: null, info: null };
	if (info.isSymbolicLink() || !info.isFile()) {
		fail("package.json must be a regular file", { path: packagePath });
	}
	const raw = await fs.readFile(packagePath, "utf8");
	let value;
	try {
		value = JSON.parse(raw);
	} catch (error) {
		fail("Existing package.json is invalid JSON", {
			path: packagePath,
			cause: error.message,
		});
	}
	if (!isPlainObject(value)) {
		fail("Existing package.json must contain a JSON object", {
			path: packagePath,
		});
	}
	return { value, raw, info };
}

function resolvePackageContract(
	stack,
	variant,
	selectedTools,
	toolRegistry,
	variables,
) {
	let desired = {};
	const dependencies = new Set();
	const devDependencies = new Set();
	const allowedBuilds = new Set();
	const removals = new Set();
	for (const manifest of [...stack, variant].filter(Boolean)) {
		desired = mergeObjects(
			desired,
			renderDeep(manifest.packageJson ?? {}, variables),
		);
		for (const pointer of manifest.omitPackageJson ?? []) {
			removePointer(desired, pointer);
		}
		for (const item of manifest.dependencies ?? []) dependencies.add(item);
		for (const item of manifest.devDependencies ?? [])
			devDependencies.add(item);
		for (const item of manifest.allowedBuilds ?? []) allowedBuilds.add(item);
		for (const pointer of manifest.removePackageJson ?? []) {
			pointerSegments(pointer);
			removals.add(pointer);
		}
	}
	const core = {
		dependencies: [...dependencies],
		devDependencies: [...devDependencies],
	};
	const optionalDependencies = new Set();
	const optionalDevDependencies = new Set();
	for (const toolId of selectedTools) {
		const tool = toolRegistry.get(toolId);
		desired = mergeObjects(
			desired,
			renderDeep(tool.packageJson ?? {}, variables),
		);
		for (const item of tool.dependencies ?? []) optionalDependencies.add(item);
		for (const item of tool.devDependencies ?? [])
			optionalDevDependencies.add(item);
	}
	return {
		desired,
		core,
		optional: {
			dependencies: [...optionalDependencies],
			devDependencies: [...optionalDevDependencies],
		},
		allowedBuilds: [...allowedBuilds],
		removals: [...removals],
	};
}

function dependencyNames(packageValue) {
	return new Set([
		...Object.keys(packageValue?.dependencies ?? {}),
		...Object.keys(packageValue?.devDependencies ?? {}),
		...Object.keys(packageValue?.optionalDependencies ?? {}),
	]);
}

function installCommands(
	packageManager,
	requirements,
	installed,
	allowedBuilds = [],
) {
	if (!packageManager) return [];
	const commands = [];
	const dependencies = requirements.dependencies.filter(
		(item) => !installed.has(item),
	);
	const devDependencies = requirements.devDependencies.filter(
		(item) => !installed.has(item) && !dependencies.includes(item),
	);
	const add =
		packageManager === "bun"
			? "bun add"
			: packageManager === "pnpm"
				? `pnpm${allowedBuilds.map((item) => ` --allow-build=${item}`).join("")} add`
				: `${packageManager} add`;
	if (dependencies.length) commands.push(`${add} ${dependencies.join(" ")}`);
	if (devDependencies.length) {
		commands.push(
			`${add} ${packageManager === "bun" ? "-d" : "-D"} ${devDependencies.join(" ")}`,
		);
	}
	return commands;
}

function resolveCommands(
	stack,
	variant,
	variables,
	packageContract,
	packageValue,
	packageManager,
) {
	const merged = {};
	for (const manifest of stack) Object.assign(merged, manifest.commands ?? {});
	if (variant?.commands) Object.assign(merged, variant.commands);
	const installed = dependencyNames(packageValue);
	const coreInstalled = new Set(installed);
	const install = installCommands(
		packageManager,
		packageContract.core,
		coreInstalled,
		packageContract.allowedBuilds,
	);
	for (const item of [
		...packageContract.core.dependencies,
		...packageContract.core.devDependencies,
	]) {
		coreInstalled.add(item);
	}
	return {
		framework: merged.framework
			? renderTemplate(merged.framework, variables)
			: null,
		frameworkCwd: merged.frameworkCwd
			? renderTemplate(merged.frameworkCwd, variables)
			: null,
		install,
		setup: (merged.setup ?? []).map((command) =>
			renderTemplate(command, variables),
		),
		optional: installCommands(
			packageManager,
			packageContract.optional,
			coreInstalled,
		),
		typecheck: renderTemplate(
			merged.typecheck ?? variant?.typecheck ?? "",
			variables,
		),
	};
}

function shellQuote(value) {
	if (/^[A-Za-z0-9_./:@%+=,-]+$/.test(value)) return value;
	return `'${value.replaceAll("'", `'"'"'`)}'`;
}

function validPackageName(value) {
	return (
		typeof value === "string" &&
		value.length > 0 &&
		value.length <= 214 &&
		value === value.toLowerCase() &&
		/^(?:@[a-z0-9._~-]+\/)?[a-z0-9._~-]+$/.test(value)
	);
}

function readinessContract(stack, variant) {
	const files = new Set();
	const packages = new Set();
	for (const source of [...stack, variant].filter(Boolean)) {
		for (const item of source.readiness?.files ?? []) files.add(item);
		for (const item of source.readiness?.packages ?? []) packages.add(item);
	}
	return { files: [...files], packages: [...packages] };
}

async function readinessStatus(target, contract, packageValue) {
	const missingFiles = [];
	for (const file of contract.files) {
		const safe = validateOutputTarget(file);
		const info = await pathInfo(path.join(target, safe));
		if (!info?.isFile() || info.isSymbolicLink()) missingFiles.push(safe);
	}
	const installed = dependencyNames(packageValue);
	const missingPackages = contract.packages.filter(
		(item) => !installed.has(item),
	);
	return {
		ready: missingFiles.length === 0 && missingPackages.length === 0,
		missingFiles,
		missingPackages,
	};
}

async function inspectOutput(target, output) {
	const destination = path.resolve(target, output.target);
	if (!isInside(target, destination)) {
		fail(`Output escapes target: ${output.target}`);
	}
	await assertNoSymlinks(destination);
	const info = await pathInfo(destination);
	if (!info) return { status: "create", destination };
	if (!info.isFile()) {
		fail("Output destination exists but is not a regular file", {
			target: output.target,
			destination,
		});
	}
	const current = await fs.readFile(destination);
	return {
		status: current.equals(output.content) ? "unchanged" : "overwrite",
		destination,
	};
}

async function buildPlan(options) {
	if (!options.template) fail("--template is required");
	if (!options.target) fail("--target is required");
	const target = path.resolve(options.target);
	await assertSafeTarget(target);
	const stack = await resolveStack(options.template);
	const variant = resolveVariant(stack, options.variant);
	const packageManager = resolvedPackageManager(stack);
	const targetName = path.basename(target);
	const projectName = options.name ?? targetName;
	if (
		stack.some((manifest) => manifest.packageJson) &&
		!validPackageName(projectName)
	) {
		fail(`Invalid package name: ${projectName}`, {
			hint: "Pass a lowercase npm-compatible name with --name",
		});
	}
	const variables = {
		packageManager: packageManager ?? "none",
		pmExec: packageManager === "bun" ? "bunx" : `${packageManager} exec`,
		projectName,
		targetName,
		targetArg: shellQuote(targetName),
		targetParent: path.dirname(target),
		variant: variant?.id ?? "",
		variantArg: shellQuote(variant?.id ?? ""),
		typecheckCommand: variant
			? `${packageManager} run typecheck`
			: (stack.at(-1).commands?.typecheck ?? ""),
		frameworkName:
			variant?.frameworkName ?? stack.at(-1).frameworkName ?? stack.at(-1).id,
	};
	const toolRegistry = mergeOptionalTools(stack);
	const selectedTools = [...new Set(options.optional ?? [])];
	const unknownTools = selectedTools.filter((tool) => !toolRegistry.has(tool));
	if (unknownTools.length) {
		fail("Unknown optional tools", {
			unknownTools,
			availableOptionalTools: [...toolRegistry.keys()],
		});
	}
	const documents = await composeDocuments(stack, variables);
	const assets = await collectAssets(
		stack,
		selectedTools,
		toolRegistry,
		variables,
	);
	const outputs = [...documents, ...assets];
	const byTarget = new Map();
	for (const output of outputs) {
		if (byTarget.has(output.target)) {
			fail(`Duplicate output target: ${output.target}`);
		}
		byTarget.set(output.target, output);
	}

	const existingPackage = await loadPackage(target);
	const packageContract = resolvePackageContract(
		stack,
		variant,
		selectedTools,
		toolRegistry,
		variables,
	);
	const managesPackage = Object.keys(packageContract.desired).length > 0;
	let packageOutput = null;
	let packageChanges = [];
	let packageCollisions = [];
	if (managesPackage) {
		const merged = mergeManagedPackage(
			existingPackage.value,
			packageContract.desired,
			packageContract.removals,
		);
		packageChanges = merged.changes;
		packageCollisions = merged.collisions;
		const formatting = packageFormatting(existingPackage.raw);
		packageOutput = {
			target: "package.json",
			content: serializePackage(merged.result, formatting),
			mode: existingPackage.info?.mode
				? existingPackage.info.mode & 0o777
				: 0o644,
			kind: "package",
			origin: "semantic-merge",
			source: "generated",
			existed: Boolean(existingPackage.info),
		};
	}

	const files = [];
	const fileCollisions = [];
	for (const output of [...byTarget.values()].sort((left, right) =>
		left.target.localeCompare(right.target),
	)) {
		const inspection = await inspectOutput(target, output);
		if (inspection.status === "overwrite") fileCollisions.push(output.target);
		files.push({
			target: output.target,
			status: inspection.status,
			kind: output.kind,
			origin: output.origin,
			source: output.source,
		});
	}
	if (packageOutput) {
		const packageStatus = !existingPackage.info
			? "create"
			: packageChanges.length
				? "merge"
				: "unchanged";
		files.push({
			target: "package.json",
			status: packageStatus,
			kind: "package",
			origin: "semantic-merge",
			source: "generated",
		});
	}
	files.sort((left, right) => left.target.localeCompare(right.target));

	const commands = resolveCommands(
		stack,
		variant,
		variables,
		packageContract,
		existingPackage.value,
		packageManager,
	);
	const deepest = stack.at(-1);
	const requiresFrameworkReady = Boolean(deepest.requiresFrameworkReady);
	const readiness = await readinessStatus(
		target,
		readinessContract(stack, variant),
		existingPackage.value,
	);
	const frameworkReady = !requiresFrameworkReady || readiness.ready;
	const lifecycle = {
		order: commands.framework
			? requiresFrameworkReady
				? ["framework", "overlay", "post-install"]
				: ["overlay", "framework", "post-install"]
			: packageManager
				? ["overlay", "post-install"]
				: ["overlay"],
		requiresFrameworkReady,
		frameworkReady,
		frameworkCommand: commands.framework,
		frameworkCwd: commands.frameworkCwd,
		missingFiles: readiness.missingFiles,
		missingPackages: readiness.missingPackages,
	};
	const notes = [
		...stack.flatMap((manifest) => manifest.planNotes ?? []),
		...(variant?.planNotes ?? []),
		...selectedTools.flatMap((toolId) => toolRegistry.get(toolId).notes ?? []),
	].map((note) => renderTemplate(note, variables));
	const collisions = [...fileCollisions, ...packageCollisions];
	return {
		ok: true,
		action: "plan",
		template: deepest.id === "_base" ? "base-only" : deepest.id,
		variant: variant?.id ?? null,
		stack: stack.map((manifest) => manifest.id),
		description: deepest.description,
		target,
		targetExists: await exists(target),
		projectName,
		packageManager,
		selectedOptionalTools: selectedTools,
		availableOptionalTools: [...toolRegistry.values()].map(
			({ id, description }) => ({ id, description }),
		),
		files,
		packageChanges,
		collisions,
		commands,
		notes,
		lifecycle,
		canApply: collisions.length === 0 && frameworkReady,
		blockedReasons: [
			...(collisions.length
				? [`Explicit approval required for: ${collisions.join(", ")}`]
				: []),
			...(!frameworkReady
				? [
						"Initialize the requested framework and rerun plan before applying the convention overlay",
					]
				: []),
		],
		_outputs: [...byTarget.values()],
		_packageOutput: packageOutput,
	};
}

function publicPlan(plan) {
	const { _outputs, _packageOutput, ...serializable } = plan;
	return serializable;
}

async function safeWrite(target, output) {
	const destination = path.resolve(target, output.target);
	if (!isInside(target, destination))
		fail(`Output escapes target: ${output.target}`);
	await fs.mkdir(path.dirname(destination), { recursive: true });
	await assertNoSymlinks(destination);
	const temporary = path.join(
		path.dirname(destination),
		`.project-init-${path.basename(destination)}-${randomUUID()}.tmp`,
	);
	let handle;
	try {
		handle = await fs.open(temporary, "wx", output.mode & 0o777);
		await handle.writeFile(output.content);
		await handle.chmod(output.mode & 0o777);
		await handle.close();
		handle = null;
		await assertNoSymlinks(destination);
		await fs.rename(temporary, destination);
	} finally {
		if (handle) await handle.close().catch(() => {});
		await fs.rm(temporary, { force: true }).catch(() => {});
	}
}

async function applyPlan(plan, approvals) {
	const approved = new Set(approvals);
	const invalidApprovals = [...approved].filter(
		(item) => !plan.collisions.includes(item),
	);
	if (invalidApprovals.length) {
		fail(
			"Approval contains entries that are not collisions",
			{ invalidApprovals, collisions: plan.collisions },
			2,
		);
	}
	const unapproved = plan.collisions.filter((item) => !approved.has(item));
	if (unapproved.length) {
		fail(
			"Explicit approval required",
			{ collisions: plan.collisions, unapproved },
			2,
		);
	}
	if (!plan.lifecycle.frameworkReady) {
		fail(
			"Framework initialization must run before the overlay",
			{ lifecycle: plan.lifecycle },
			2,
		);
	}
	await assertSafeTarget(plan.target);
	await fs.mkdir(plan.target, { recursive: true });
	const created = [];
	const overwritten = [];
	const unchanged = [];
	const merged = [];
	for (const output of plan._outputs) {
		const filePlan = plan.files.find((file) => file.target === output.target);
		if (filePlan.status === "unchanged") {
			unchanged.push(output.target);
			continue;
		}
		await safeWrite(plan.target, output);
		if (filePlan.status === "overwrite") overwritten.push(output.target);
		else created.push(output.target);
	}
	if (plan._packageOutput) {
		const filePlan = plan.files.find((file) => file.target === "package.json");
		if (filePlan.status === "unchanged") unchanged.push("package.json");
		else {
			await safeWrite(plan.target, plan._packageOutput);
			if (filePlan.status === "merge") merged.push("package.json");
			else created.push("package.json");
		}
	}
	return {
		...publicPlan(plan),
		action: "apply",
		applied: true,
		created: created.sort(),
		overwritten: overwritten.sort(),
		merged: merged.sort(),
		unchanged: unchanged.sort(),
		preservedExistingFiles: true,
	};
}

async function main() {
	const options = parseArgs(process.argv.slice(2));
	if (options.action === "list") {
		return { ok: true, templates: await listTemplates() };
	}
	const plan = await buildPlan(options);
	return options.action === "apply"
		? await applyPlan(plan, options.approve)
		: publicPlan(plan);
}

try {
	const result = await main();
	process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
} catch (error) {
	const known = error instanceof ProjectInitError;
	process.stdout.write(
		`${JSON.stringify(
			{
				ok: false,
				error: known ? error.message : "Unexpected project-init failure",
				...(known ? error.details : { cause: error.message }),
			},
			null,
			2,
		)}\n`,
	);
	process.exitCode = known ? error.exitCode : 1;
}
