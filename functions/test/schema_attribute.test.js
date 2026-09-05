import test from 'node:test';
import assert from 'node:assert/strict';
import { schemaAttribute } from '../../scripts/lib/schema_attribute.mjs';
test('schema snapshots serialize actual attributes rather than null entries', () => {
  assert.deepEqual([{ key: 'name', type: 'string', size: 100, required: true }].map(schemaAttribute),
    [{ key: 'name', type: 'string', size: 100, array: false, required: true }]);
});
test('schema snapshots preserve zero bounds and enum values but omit server metadata', () => {
  assert.deepEqual(schemaAttribute({key:'count',type:'integer',min:0,max:0,$id:'server'}),
    {key:'count',type:'integer',array:false,required:false,min:0,max:0});
  assert.deepEqual(schemaAttribute({key:'state',type:'enum',elements:['open'],array:true}),
    {key:'state',type:'enum',array:true,required:false,elements:['open']});
});
