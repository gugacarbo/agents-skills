"""Regression checks for measured evidence, not skill prose."""
import importlib.util
from pathlib import Path
import unittest
import subprocess
import sys
import tempfile

SPEC = importlib.util.spec_from_file_location('implementation_measure', Path(__file__).resolve().parents[1] / 'evals/measure.py')
measure = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(measure)


def agent(model='gpt-6-luna', effort='medium', usage=None, status='task_complete'):
    return {'model': model, 'effort': effort, 'status': status,
            'usage': usage if usage is not None else {
                'input_tokens': 100, 'cached_input_tokens': 80,
                'output_tokens': 10, 'reasoning_output_tokens': 5, 'total_tokens': 110}}


class MeasurementTests(unittest.TestCase):
    def test_totals_include_descendants_without_adding_subset_tokens_twice(self):
        result = measure.summarize_usage([agent(), agent()])
        self.assertEqual(result['total_tokens'], 220)
        self.assertEqual(result['input_tokens'] - result['cached_input_tokens'], 40)

    def test_missing_required_counters_stay_unavailable(self):
        self.assertIsNone(measure.summarize_usage([agent(usage={})]))

    def test_model_mismatch_is_not_eligible_even_after_successful_cli_exit(self):
        timing = {'completion_status': 'completed', 'exit_code': 0, 'timed_out': False, 'kind': 'execution'}
        self.assertFalse(measure.eligible(timing, [agent(), agent(model='gpt-6.2-sol')]))

    def test_controller_only_execution_is_not_an_actual_orchestration(self):
        timing = {'completion_status': 'completed', 'exit_code': 0, 'timed_out': False, 'kind': 'execution'}
        self.assertFalse(measure.eligible(timing, [agent()]))
        self.assertTrue(measure.eligible(timing, [agent(), agent()]))

    def test_interrupted_and_incomplete_attempts_are_excluded(self):
        timing = {'completion_status': 'interrupted_setup', 'exit_code': 0, 'timed_out': False, 'kind': 'execution'}
        self.assertFalse(measure.eligible(timing, [agent(), agent()]))
        timing['completion_status'] = 'completed'
        self.assertFalse(measure.eligible(timing, [agent(), agent(status='turn_aborted')]))


    def test_execution_slot_excludes_other_runner_and_releases_after_exit(self):
        probe = """import fcntl,sys
with open(sys.argv[1], 'a') as handle:
    try:
        fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        sys.exit(23)
"""
        with tempfile.TemporaryDirectory() as temporary:
            lock = Path(temporary) / 'execution.lock'
            with measure.execution_slot(lock) as waiting:
                self.assertGreaterEqual(waiting, 0)
                result = subprocess.run([sys.executable, '-c', probe, str(lock)])
                self.assertEqual(result.returncode, 23)
            result = subprocess.run([sys.executable, '-c', probe, str(lock)])
            self.assertEqual(result.returncode, 0)

    def test_execution_slot_releases_after_failed_attempt(self):
        with tempfile.TemporaryDirectory() as temporary:
            lock = Path(temporary) / 'execution.lock'
            with self.assertRaisesRegex(RuntimeError, 'attempt failed'):
                with measure.execution_slot(lock):
                    raise RuntimeError('attempt failed')
            with measure.execution_slot(lock) as waiting:
                self.assertGreaterEqual(waiting, 0)


if __name__ == '__main__':
    unittest.main()
