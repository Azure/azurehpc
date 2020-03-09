import unittest

import azconfig

class TestConfigFile(unittest.TestCase):

    def setUp(self):
        self.config = azconfig.ConfigFile()
        self.config.open("test/test_config_file.json")

    def test_read_simple_value(self):
        self.assertEqual(self.config.read_value("int_value"), 42)
    
    def test_read_boolean_value(self):
        self.assertEqual(self.config.read_value("bool_value"), True)

    def test_read_variable(self):
        self.assertEqual(self.config.read_value("use_variable"), 42)

    def test_replace_double_curly_braces(self):
        self.assertEqual(self.config.read_value("double_curly_braces"), "simple_variable=42")

if __name__ == "__main__":
    unittest.main()