function merged = mergeConfig(defaults, overrides)

merged = defaults;
overrideFields = fieldnames(overrides);
for idx = 1:numel(overrideFields)
    merged.(overrideFields{idx}) = overrides.(overrideFields{idx});
end

end
