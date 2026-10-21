"""Reference model for the fixed-width EEG convolution accelerator."""

from __future__ import annotations

MASK32 = 0xFFFFFFFF


def to_u32(value: int) -> int:
    return value & MASK32


def to_s32(value: int) -> int:
    value &= MASK32
    return value if value < 0x80000000 else value - 0x100000000


def convolve(samples: list[int], coefficients: list[int]) -> int:
    if len(samples) != len(coefficients):
        raise ValueError("samples and coefficients must have the same length")
    total = sum(to_s32(sample) * to_s32(coefficient) for sample, coefficient in zip(samples, coefficients))
    return to_s32(total)


def convolution_window(samples: list[int], coefficients: list[int], start: int = 0) -> int:
    window = samples[start : start + len(coefficients)]
    if len(window) != len(coefficients):
        raise ValueError("window extends beyond the sample buffer")
    return convolve(window, coefficients)


def stream_convolution(samples: list[int], coefficients: list[int]) -> list[int]:
    if len(coefficients) == 0:
        raise ValueError("coefficients must not be empty")
    outputs = []
    for end in range(len(coefficients), len(samples) + 1):
        window = list(reversed(samples[end - len(coefficients) : end]))
        outputs.append(convolve(window, coefficients))
    return outputs
