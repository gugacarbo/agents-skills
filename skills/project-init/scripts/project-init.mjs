#!/usr/bin/env node

import { promises as fs } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const skillDirectory = path.dirname(
	path.dirname(fileURLToPath(import.meta.url)),
);
const templatesDirectory = path.join(skillDirectory, "templates");
const supportedActions = new Set(["list", "plan", "apply"]);

function fail(message, details = {}, exitCode = 1) {
	process.stdout.write(
		`${JSON.stringify({ ok: false, error: message, ...details }, null, 2)}\n`,
	);
	process.exit(exitCode);
}

function parseArgs(argv) {
	const [action, ...rest] = argv;
	if (!supportedActions.has(action)) {
		fail("Expected one of: list, plan, apply", { received: action ?? null });
	}
	const options = { action, optional: [], approve: [] };
	for (let index = 0; index < rest.length; index += 1) {
		const argument = rest[index];
		if (!argument.startsWith("--")) fail(`Unexpected argument: ${argument}`);
		const key = argument.slice(2);
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

async function exists(filePath) {
	try {
		await fs.access(filePath);
		return true;
	} catch {
		return false;
	}
}

async function loadManifest(templateId) {
	const manifestPath = path.join(
		templatesDirectory,
		templateId,
		"template.json",
	);
	if (!(await exists(manifestPath)))
		fail(`Unknown template: ${templateId}`, {
			available: await listTemplates(),
		});
	const manifest = JSON.parse(await fs.readFile(manifestPath, "utf8"));
	if (manifest.id !== templateId)
		fail(`Manifest id mismatch for ${templateId}`);
	return { ...manifest, directory: path.dirname(manifestPath) };
}

async function listTemplates() {
	const found = [];
	async function visit(relative = "") {
		const absolute = path.join(templatesDirectory, relative);
		for (const entry of await fs.readdir(absolute, { withFileTypes: true })) {
			if (
				!entry.isDirectory() ||
				(entry.name.startsWith("_") && entry.name !== "_base")
			)
				continue;
			const child = path.join(relative, entry.name);
			const manifestPath = path.join(
				templatesDirectory,
				child,
				"template.json",
			);
			if (await exists(manifestPath)) {
				const manifest = JSON.parse(await fs.readFile(manifestPath, "utf8"));
				found.push({
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

async function composeDocuments(stack, variables) {
	const documents = new Map();
	for (const manifest of stack) {
		for (const [target, source] of Object.entries(manifest.documents ?? {})) {
			const sourcePath = path.resolve(manifest.directory, source);
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
				if (!current.sections.has(section.heading))
					current.order.push(section.heading);
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
		const content = `${title}\n\n${document.order.map((heading) => document.sections.get(heading)).join("\n\n")}\n`;
		return {
			target,
			content,
			kind: "document",
			origin: Object.fromEntries(
				document.order.map((heading) => [
					heading,
					document.origins.get(heading),
				]),
			),
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
		if (requestedVariant)
			fail(`Template ${deepest.id} does not accept --variant`);
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
				commands: {},
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
				commands: { ...previous.commands, ...(definition.commands ?? {}) },
				notes: [...previous.notes, ...(definition.notes ?? [])],
			});
		}
	}
	return tools;
}

function resolveCommands(
	stack,
	variant,
	variables,
	selectedTools,
	toolRegistry,
) {
	const merged = {};
	for (const manifest of stack) Object.assign(merged, manifest.commands ?? {});
	if (variant?.commands) Object.assign(merged, variant.commands);
	const renderMany = (values = []) =>
		values.map((value) => renderTemplate(value, variables));
	const optional = selectedTools.flatMap((id) => {
		const tool = toolRegistry.get(id);
		const command =
			tool.commands?.[variables.packageManager] ?? tool.commands?.default;
		return command ? [renderTemplate(command, variables)] : [];
	});
	return {
		framework: merged.framework
			? renderTemplate(merged.framework, variables)
			: null,
		frameworkCwd: merged.frameworkCwd
			? renderTemplate(merged.frameworkCwd, variables)
			: null,
		install: renderMany(merged.install),
		setup: renderMany(merged.setup),
		optional,
		typecheck: renderTemplate(
			merged.typecheck ?? variant?.typecheck ?? "",
			variables,
		),
	};
}

function ensureSourceInsideTemplates(sourcePath) {
	const relative = path.relative(templatesDirectory, sourcePath);
	if (relative.startsWith("..") || path.isAbsolute(relative))
		fail(`Asset escapes templates directory: ${sourcePath}`);
}

async function collectAssets(stack, selectedTools, toolRegistry, variables) {
	const assets = new Map();
	async function addAsset(file, manifest, kind) {
		const source = path.resolve(manifest.directory, file.source);
		ensureSourceInsideTemplates(source);
		if (!(await exists(source))) fail(`Missing template asset: ${source}`);
		const stat = await fs.stat(source);
		const raw = await fs.readFile(source);
		const isText = !raw.includes(0);
		const content = isText
			? Buffer.from(renderTemplate(raw.toString("utf8"), variables))
			: raw;
		assets.set(file.target, {
			target: file.target,
			content,
			mode: stat.mode,
			kind,
			origin: manifest.id,
			source: path.relative(skillDirectory, source).replaceAll(path.sep, "/"),
		});
	}
	for (const manifest of stack) {
		for (const file of manifest.files ?? [])
			await addAsset(file, manifest, "file");
	}
	for (const toolId of selectedTools) {
		for (const file of toolRegistry.get(toolId).files ?? []) {
			await addAsset(file, file.manifest, `optional:${toolId}`);
		}
	}
	return [...assets.values()];
}

async function buildPlan(options) {
	if (!options.template) fail("--template is required");
	if (!options.target) fail("--target is required");
	const target = path.resolve(options.target);
	const stack = await resolveStack(options.template);
	const variant = resolveVariant(stack, options.variant);
	const packageManager = resolvedPackageManager(stack);
	const targetName = path.basename(target);
	const variables = {
		packageManager: packageManager ?? "none",
		pmExec: packageManager === "bun" ? "bunx" : `${packageManager} exec`,
		projectName: options.name ?? targetName,
		targetName,
		variant: variant?.id ?? "",
		typecheckCommand:
			variant?.typecheck ?? stack.at(-1).commands?.typecheck ?? "",
		frameworkName:
			variant?.frameworkName ?? stack.at(-1).frameworkName ?? stack.at(-1).id,
	};
	const toolRegistry = mergeOptionalTools(stack);
	const selectedTools = [...new Set(options.optional ?? [])];
	const unknownTools = selectedTools.filter((tool) => !toolRegistry.has(tool));
	if (unknownTools.length)
		fail("Unknown optional tools", {
			unknownTools,
			availableOptionalTools: [...toolRegistry.keys()],
		});
	const documents = await composeDocuments(stack, variables);
	const assets = await collectAssets(
		stack,
		selectedTools,
		toolRegistry,
		variables,
	);
	const outputs = [
		...documents.map((document) => ({
			...document,
			content: Buffer.from(document.content),
			mode: 0o100644,
			source: "generated",
		})),
		...assets,
	];
	const byTarget = new Map(outputs.map((output) => [output.target, output]));
	const files = [];
	const collisions = [];
	for (const output of [...byTarget.values()].sort((left, right) =>
		left.target.localeCompare(right.target),
	)) {
		const destination = path.join(target, output.target);
		let status = "create";
		if (await exists(destination)) {
			const current = await fs.readFile(destination);
			status = current.equals(output.content) ? "unchanged" : "overwrite";
			if (status === "overwrite") collisions.push(output.target);
		}
		files.push({
			target: output.target,
			status,
			kind: output.kind,
			origin: output.origin,
			source: output.source,
		});
	}
	const commands = resolveCommands(
		stack,
		variant,
		variables,
		selectedTools,
		toolRegistry,
	);
	const deepest = stack.at(-1);
	const requiresFrameworkReady = Boolean(deepest.requiresFrameworkReady);
	const frameworkReady =
		!requiresFrameworkReady ||
		(await exists(path.join(target, "package.json")));
	const lifecycle = {
		order: requiresFrameworkReady
			? ["framework", "overlay", "post-install"]
			: ["overlay", "framework", "post-install"],
		requiresFrameworkReady,
		frameworkReady,
		frameworkCommand: commands.framework,
		frameworkCwd: commands.frameworkCwd,
	};
	const notes = [
		...stack.flatMap((manifest) => manifest.planNotes ?? []),
		...(variant?.planNotes ?? []),
		...selectedTools.flatMap((toolId) => toolRegistry.get(toolId).notes ?? []),
	].map((note) => renderTemplate(note, variables));
	return {
		ok: true,
		action: "plan",
		template: deepest.id === "_base" ? "base-only" : deepest.id,
		variant: variant?.id ?? null,
		stack: stack.map((manifest) => manifest.id),
		description: deepest.description,
		target,
		targetExists: await exists(target),
		packageManager,
		selectedOptionalTools: selectedTools,
		availableOptionalTools: [...toolRegistry.values()].map(
			({ id, description }) => ({ id, description }),
		),
		files,
		collisions,
		commands,
		notes,
		lifecycle,
		canApply: collisions.length === 0 && frameworkReady,
		blockedReasons: [
			...(collisions.length
				? [`Overwrite approval required for: ${collisions.join(", ")}`]
				: []),
			...(!frameworkReady
				? ["Run the framework command before applying the convention overlay"]
				: []),
		],
		_outputs: [...byTarget.values()],
	};
}

function publicPlan(plan) {
	const { _outputs, ...serializable } = plan;
	return serializable;
}

async function applyPlan(plan, approvals) {
	const approved = new Set(approvals);
	const invalidApprovals = [...approved].filter(
		(file) => !plan.collisions.includes(file),
	);
	if (invalidApprovals.length)
		fail(
			"Approval contains paths that are not collisions",
			{ invalidApprovals, collisions: plan.collisions },
			2,
		);
	const unapproved = plan.collisions.filter((file) => !approved.has(file));
	if (unapproved.length) {
		fail(
			"Explicit overwrite approval required",
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
	const created = [];
	const overwritten = [];
	const unchanged = [];
	await fs.mkdir(plan.target, { recursive: true });
	for (const output of plan._outputs) {
		const destination = path.join(plan.target, output.target);
		const filePlan = plan.files.find((file) => file.target === output.target);
		if (filePlan.status === "unchanged") {
			unchanged.push(output.target);
			continue;
		}
		await fs.mkdir(path.dirname(destination), { recursive: true });
		await fs.writeFile(destination, output.content);
		await fs.chmod(destination, output.mode & 0o777);
		if (filePlan.status === "overwrite") overwritten.push(output.target);
		else created.push(output.target);
	}
	return {
		...publicPlan(plan),
		action: "apply",
		applied: true,
		created,
		overwritten,
		unchanged,
		preservedExistingFiles: true,
	};
}

const options = parseArgs(process.argv.slice(2));
if (options.action === "list") {
	process.stdout.write(
		`${JSON.stringify({ ok: true, templates: await listTemplates() }, null, 2)}\n`,
	);
} else {
	const plan = await buildPlan(options);
	const result =
		options.action === "apply"
			? await applyPlan(plan, options.approve)
			: publicPlan(plan);
	process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
}
