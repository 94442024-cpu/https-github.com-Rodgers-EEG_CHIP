import unittest

from convolution_model import convolve, convolution_window, to_s32, to_u32


class ConvolutionModelTests(unittest.TestCase):
    def test_signed_four_tap_convolution(self):
        self.assertEqual(convolve([3, -2, 5, 1], [-4, 6, 2, -3]), -17)

    def test_result_wraps_to_signed_32_bits(self):
        result = convolve([0x7FFFFFFF, 0x7FFFFFFF], [2, 2])
        self.assertEqual(result, -4)
        self.assertEqual(to_s32(to_u32(result)), -4)

    def test_window_selection(self):
        samples = [1, 2, 3, 4, 5, 6]
        coefficients = [2, -1, 3]
        self.assertEqual(convolution_window(samples, coefficients, start=1), 13)

    def test_rejects_mismatched_lengths(self):
        with self.assertRaises(ValueError):
            convolve([1], [1, 2])


if __name__ == "__main__":
    unittest.main()
