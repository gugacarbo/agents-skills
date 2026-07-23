import type { PackageJson } from '../types/package-json.ts';
declare const INDENT: unique symbol;
declare const NEWLINE: unique symbol;
interface ExtendedPackageJson extends PackageJson {
    [INDENT]?: string;
    [NEWLINE]?: string;
}
export declare const getPackageMapTarget: (map: unknown, key: string) => {
    target: any;
    patternMatch?: undefined;
} | {
    target: unknown;
    patternMatch: string;
} | undefined;
export declare const load: (filePath: string) => Promise<ExtendedPackageJson>;
export declare const save: (filePath: string, content: ExtendedPackageJson) => Promise<void>;
export declare const getEntrySpecifiersFromManifest: (manifest: PackageJson) => Set<string>;
export type Manifest = PackageJson & {
    scriptNames: Set<string>;
    getMajor: (name: string) => number | undefined;
};
export declare const createManifest: (raw: PackageJson) => Manifest;
export declare const getManifestImportDependencies: (manifest: PackageJson) => Set<string>;
export {};
