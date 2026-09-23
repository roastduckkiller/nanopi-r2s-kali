import copy
import importlib.util
from pathlib import Path
import unittest
spec = importlib.util.spec_from_file_location('layout', Path(__file__).parents[1] / 'scripts/layout.py')
layout = importlib.util.module_from_spec(spec)
spec.loader.exec_module(layout)

class LayoutTests(unittest.TestCase):
    def setUp(self):
        self.table = {'partitiontable': {
            'label': 'gpt', 'sectorsize': 512, 'id': '00000000-0000-4000-8000-000000000000',
            'partitions': [dict(start=start, size=layout.SIZES[i] if i < 8 else 25653215,
                                name=layout.NAMES[i], type='0FC63DAF-8483-4772-8E79-3D69D8477DE4',
                                uuid=f'00000000-0000-4000-8000-{i+1:012d}')
                           for i, start in enumerate(layout.STARTS)]}}

    def test_compact_fits_and_preserves_offsets(self):
        result = layout.compact(self.table)
        self.assertIn('last-lba: 5242846', result)
        self.assertIn('start=4718592, size=524255', result)
        self.assertIn('start=262144, size=4456448', result)
        self.assertEqual(self.table['partitiontable']['partitions'][8]['size'], 25653215)

    def test_rejects_different_hardware_layout(self):
        for field, value in [('label', 'dos'), ('sectorsize', 4096)]:
            table = copy.deepcopy(self.table)
            table['partitiontable'][field] = value
            with self.assertRaises(ValueError): layout.compact(table)
        for index, field, value in [(7, 'start', 2048), (6, 'size', 4096),
                                    (8, 'size', 100), (7, 'name', 'other')]:
            table = copy.deepcopy(self.table)
            table['partitiontable']['partitions'][index][field] = value
            with self.assertRaises(ValueError): layout.compact(table)

    def test_rejects_missing_and_extra_partitions(self):
        for count in [8, 10]:
            table = copy.deepcopy(self.table)
            table['partitiontable']['partitions'] = (table['partitiontable']['partitions'] * 2)[:count]
            with self.assertRaises(ValueError): layout.compact(table)

if __name__ == '__main__': unittest.main()
