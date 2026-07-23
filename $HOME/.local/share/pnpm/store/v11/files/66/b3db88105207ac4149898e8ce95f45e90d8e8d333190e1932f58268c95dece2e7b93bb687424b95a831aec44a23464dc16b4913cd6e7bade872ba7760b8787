import { collectPropertyValues } from '../../typescript/ast-helpers.js';
import { toDependency, toProductionEntry } from '../../util/input.js';
import { hasDependency } from '../../util/plugin.js';
const title = 'tsdown';
const enablers = ['tsdown'];
const isEnabled = ({ dependencies }) => hasDependency(dependencies, enablers);
const config = ['tsdown.config.{ts,mts,cts,js,mjs,cjs,json}', 'package.json'];
const isLoadConfig = ({ configFileName }) => configFileName === 'package.json' || configFileName.endsWith('.json');
const normalizeEntry = (entry) => {
    if (!entry)
        return [];
    if (typeof entry === 'string') {
        return [entry];
    }
    if (Array.isArray(entry)) {
        return entry.flatMap(normalizeEntry);
    }
    return Object.values(entry).flatMap(value => (Array.isArray(value) ? value : [value]));
};
const getExternalDependencies = (options) => {
    const neverBundle = options.deps?.neverBundle;
    const values = Array.isArray(neverBundle) ? neverBundle : [neverBundle];
    return values.filter(value => typeof value === 'string');
};
const resolveConfig = async (config) => {
    if (typeof config === 'function')
        config = await config({});
    const entryPatterns = [config]
        .flat()
        .flatMap(config => normalizeEntry(config.entry))
        .map(id => toProductionEntry(id, { allowIncludeExports: true }));
    const externalDependencies = [config]
        .flat()
        .flatMap(getExternalDependencies)
        .map(id => toDependency(id, { optional: true }));
    return [...entryPatterns, ...externalDependencies];
};
const resolveFromAST = program => [
    ...[...collectPropertyValues(program, 'entry')].map(id => toProductionEntry(id, { allowIncludeExports: true })),
    ...[...collectPropertyValues(program, 'neverBundle')].map(id => toDependency(id, { optional: true })),
];
const args = {
    config: true,
};
const plugin = {
    title,
    enablers,
    isEnabled,
    config,
    isLoadConfig,
    resolveConfig,
    resolveFromAST,
    args,
};
export default plugin;
