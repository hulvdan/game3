import logging
from contextlib import contextmanager
from functools import wraps
from time import time
from typing import Any, Callable, NoReturn, ParamSpec, TypeVar

import typer

P = ParamSpec("P")
T = TypeVar("T")

LOG_FILE_POSITION = False


class ColoredLoggingFormatter(logging.Formatter):
    # {  ###
    _grey = "\x1b[30;20m"
    _green = "\x1b[32;20m"
    _yellow = "\x1b[33;20m"
    _red = "\x1b[31;20m"
    _bold_red = "\x1b[31;1m"

    @staticmethod
    def _get_format(color: str | None) -> str:
        reset = "\x1b[0m"
        if color is None:
            color = reset

        suffix = ""
        if LOG_FILE_POSITION:
            suffix = " (%(filename)s:%(lineno)d)"

        return f"{color}[%(levelname)s] %(message)s{suffix}{reset}"

    _FORMATS = {
        logging.NOTSET: _get_format(None),
        logging.DEBUG: _get_format(None),
        logging.INFO: _get_format(_green),
        logging.WARNING: _get_format(_yellow),
        logging.ERROR: _get_format(_red),
        logging.CRITICAL: _get_format(_bold_red),
    }

    def format(self, record):
        log_fmt = self._FORMATS.get(record.levelno)
        formatter = logging.Formatter(log_fmt)
        return formatter.format(record)

    # }


log = logging.getLogger(__file__)
log.setLevel(logging.DEBUG)
console_handler = logging.StreamHandler()
console_handler.setLevel(logging.DEBUG)
console_handler.setFormatter(ColoredLoggingFormatter())
log.addHandler(console_handler)

_exiting = False

timings_stack: list[Any] = []
_root_timings_stack = timings_stack
_timing_marks: list[Any] = []
_timing_recursion_depth = 0


def timing(f: Callable[P, T]) -> Callable[P, T]:
    # {  ###
    @wraps(f)
    def wrap(*args: P.args, **kw: P.kwargs) -> T:
        global timings_stack
        global _timing_marks
        global _timing_recursion_depth

        started_at = time()

        old_stack = timings_stack
        timings_stack = []

        old_timing_marks = _timing_marks
        _timing_marks = []

        _timing_recursion_depth += 1

        try:
            result = f(*args, **kw)
        finally:
            _timing_recursion_depth -= 1

            elapsed = time() - started_at
            log.info("Running '{}' took: {:.2f} ms".format(f.__name__, elapsed * 1000))

            old_stack.append((f.__name__, elapsed, timings_stack, _timing_marks))

            timings_stack = old_stack
            _timing_marks = old_timing_marks

            if _exiting:
                print_timings()

        return result

    return wrap
    # }


def timing_mark(text):
    _timing_marks.append(text)


def print_timings():
    # {  ###
    total_elapsed = sum(i[1] for i in _root_timings_stack)
    if total_elapsed == 0:
        total_elapsed = 0.000001

    timings_string = "Timings:\n"

    def process_value(i, depth):
        nonlocal timings_string

        function_name = i[0]
        elapsed = i[1]
        nested_function_calls = i[2]
        timing_marks_list = i[3]
        timing_marks_joined = ", ".join(timing_marks_list)

        timings_string += "{}- {}".format("  " * depth, function_name).ljust(
            52
        ) + " {: 9.2f} ms, {:4.1f}%{}\n".format(
            elapsed * 1000,
            elapsed * 100 / total_elapsed,
            " ({})".format(timing_marks_joined) if timing_marks_list else "",
        )

        for v in nested_function_calls:
            process_value(v, depth + 1)

    for i in _root_timings_stack:
        process_value(i, 0)

    log.info(timings_string)

    assert _started_at is not None
    log.info("RUNNING TOOK: {:.2f} SEC".format(time() - _started_at))
    # }


_started_at = None


@contextmanager
def timing_manager():
    # {  ###
    global _exiting
    global _started_at

    _started_at = time()

    yield

    _exiting = True

    if _timing_recursion_depth == 0:
        print_timings()
    # }


global_timing_manager_instance = timing_manager()


old_exit = exit


def timed_exit(code: int) -> NoReturn:
    # {  ###
    if global_timing_manager_instance is not None:
        global_timing_manager_instance.__exit__(None, None, None)
        console_handler.flush()

    old_exit(code)
    # }


globals()["exit"] = timed_exit


def hook_exit():
    global exit
    exit = timed_exit  # type: ignore[name-defined]  # noqa: A001


app = typer.Typer(
    callback=hook_exit, result_callback=timed_exit, pretty_exceptions_enable=False
)


def command(f: Callable[P, T]) -> Callable[P, T]:
    return app.command(f.__name__)(f)


###
