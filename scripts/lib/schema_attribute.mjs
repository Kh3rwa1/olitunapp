export function schemaAttribute(attr) {
  const spec = { key: attr.key, type: attr.type };
  if (attr.size !== undefined && attr.size !== null) spec.size = attr.size;
  spec.array = attr.array || false;
  spec.required = attr.required || false;
  if (attr.elements?.length) spec.elements = attr.elements;
  if (attr.min !== undefined && attr.min !== null) spec.min = attr.min;
  if (attr.max !== undefined && attr.max !== null) spec.max = attr.max;
  return spec;
}
