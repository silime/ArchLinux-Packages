import importlib.machinery
import types
import unittest
from unittest.mock import patch
import sys

helper = importlib.machinery.SourceFileLoader('uim', sys.argv.pop(1)).load_module()


class UimTest(unittest.TestCase):
    def test_slot_and_application_pairing(self):
        text = """Primary GW:   slot '2', application '2'
Slot [1]:
 Card state: 'present'
 Application [1]:
  Application type: 'usim (2)'
  Application state: 'ready'
  Application ID:
   AA:01
Slot [2]:
 Card state: 'present'
 Application [1]:
  Application type: 'isim (5)'
  Application state: 'ready'
  Application ID:
   BB:01
 Application [2]:
  Application type: 'usim (2)'
  Application state: 'detected'
  Application ID:
   BB:02
"""
        selected, apps = helper.parse_card_status(text)
        self.assertEqual(selected, (2, 2))
        self.assertEqual(apps[0], {'slot': 2, 'app': 2, 'state': 'detected', 'aid': 'BB02'})
        self.assertEqual(len(apps), 2)

    def run_preparation(self, selected, state, mode='online', running=False):
        calls = []
        app = {'slot': 2, 'app': 1, 'state': state, 'aid': 'ABCD'}
        model = {'selected': selected}

        def status():
            return model['selected'], [dict(app)]

        def qmi(option):
            calls.append(option)
            if option == '--dms-get-operating-mode':
                return f"Mode: '{mode}'"
            if option.startswith('--uim-change-provisioning-session='):
                model['selected'] = (2, 1)
            if option == '--uim-sim-power-on=2':
                app['state'] = 'ready'
                # Some firmware loses the provisioning session after power-on.
                model['selected'] = None
            return ''

        with patch.object(helper, 'status', side_effect=status), \
             patch.object(helper, 'qmi', side_effect=qmi), \
             patch.object(helper.time, 'sleep'), \
             patch.object(helper.subprocess, 'run', return_value=types.SimpleNamespace(
                 stdout='active' if running else 'activating')):
            helper.main()
        return calls

    def test_ready_session_is_not_reset(self):
        self.assertEqual(self.run_preparation((2, 1), 'ready'), [])

    def test_missing_primary_and_detected_recovers(self):
        calls = self.run_preparation(None, 'detected', 'shutting-down')
        self.assertIn('--dms-set-operating-mode=online', calls)
        self.assertEqual(calls.count('--uim-sim-power-off=2'), 1)
        self.assertEqual(calls.count('--uim-sim-power-on=2'), 1)
        self.assertEqual(sum(c.startswith('--uim-change-provisioning-session=')
                             for c in calls), 2)

    def test_pin_locked_card_is_not_reset(self):
        self.assertEqual(self.run_preparation((2, 1), 'pin-required'), [])

    def test_running_modem_is_not_touched(self):
        with self.assertRaisesRegex(RuntimeError, 'Refusing'):
            self.run_preparation(None, 'detected', running=True)


unittest.main()
