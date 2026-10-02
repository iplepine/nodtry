module.exports = {
    root: true,
    env: {
        es2020: true,
        node: true,
    },
    extends: [
        "eslint:recommended",
        "plugin:import/errors",
        "plugin:import/warnings",
        "plugin:import/typescript",
        "google",
        "plugin:@typescript-eslint/recommended",
    ],
    parser: "@typescript-eslint/parser",
    parserOptions: {
        ecmaVersion: 2020,
        sourceType: "module",
    },
    ignorePatterns: [
        "/lib/**/*",
        "/node_modules/**/*",
    ],
    plugins: [
        "@typescript-eslint",
        "import",
    ],
    rules: {
        // House style of this repo's functions code (4-space indent, long
        // Korean copy lines) rather than the Google defaults.
        "quotes": ["error", "double", {avoidEscape: true}],
        "indent": ["error", 4],
        "max-len": ["error", {code: 120, ignoreStrings: true, ignoreTemplateLiterals: true, ignoreComments: true}],
        "object-curly-spacing": ["error", "never"],
        "require-jsdoc": "off",
        "valid-jsdoc": "off",
        "import/no-unresolved": "off",
        "operator-linebreak": "off",
    },
    overrides: [
        {
            files: ["*.js"],
            rules: {
                "@typescript-eslint/no-var-requires": "off",
            },
        },
    ],
};
