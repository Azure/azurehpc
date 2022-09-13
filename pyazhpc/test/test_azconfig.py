import unittest

import azconfig


class TestConfigFile(unittest.TestCase):

    def setUp(self):
        self.config = azconfig.ConfigFile()
        self.config.open("test/test_config_file.json")
        self.config_preprocessed = self.config.preprocess()

    def test_read_simple_value(self):
        self.assertEqual(self.config.read_value("int_value"), 42)

    def test_read_boolean_value(self):
        self.assertEqual(self.config.read_value("bool_value"), True)

    def test_read_variable(self):
        self.assertEqual(self.config.read_value("use_variable"), 42)

    def test_replace_double_curly_braces(self):
        self.assertEqual(self.config.read_value("double_curly_braces"), "simple_variable=42")

    # Before preprocessing, config fields using variable name definitions are not expanded
    def test_replace_in_dict_key_before_preprocessing(self):
        self.assertEqual(
            self.config.read_value("resources")["variables.resource_name"],
            "bar"
        )

    def test_replace_in_dict_value_before_preprocessing(self):
        self.assertEqual(
            self.config.read_value("resources")["resource-name"],
            "variables.resource_type"
        )

    # After preprocessing, config fields using variable name definitions are expanded
    def test_replace_in_dict_key_after_preprocessing(self):
        self.assertEqual(self.config_preprocessed["resources"]["foo"], "bar")

    def test_replace_in_dict_value_after_preprocessing(self):
        self.assertEqual(self.config_preprocessed["resources"]["resource-name"], "resource-type")

if __name__ == "__main__":
    unittest.main()
