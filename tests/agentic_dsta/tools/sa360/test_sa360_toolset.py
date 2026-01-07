
import unittest
from unittest import mock
import sys

# Mocking needs to be handled by the runner or inside here if run standalone
# But since we use run_tests_with_mocks.py, we can rely on it mostly,
# BUT we need to import the module under test which might fail if dependencies aren't mocked yet.
# Ideally run_tests_with_mocks.py sets up mocks BEFORE importing this.
# So we just import assuming mocks are there.

from agentic_dsta.tools.sa360 import sa360_toolset
from googleapiclient.errors import HttpError

MagicMock = mock.MagicMock
patch = mock.patch

class TestSA360Toolset(unittest.TestCase):
    
    @patch('agentic_dsta.tools.sa360.sa360_toolset.get_sheets_service')
    def test_get_campaign_details_success(self, mock_get_service):
        mock_service = MagicMock()
        mock_get_service.return_value = mock_service
        mock_sheet = MagicMock()
        mock_service.spreadsheets.return_value = mock_sheet
        
        mock_result = {
            'values': [
                ['Campaign ID', 'Name', 'Campaign status'],
                ['123', 'Campaign 1', 'ENABLED'],
                ['456', 'Campaign 2', 'PAUSED']
            ]
        }
        mock_sheet.values.return_value.get.return_value.execute.return_value = mock_result
        
        result = sa360_toolset.get_campaign_details('123', 'sheet_id', 'sheet_name')
        self.assertEqual(result, {'Campaign ID': '123', 'Name': 'Campaign 1', 'Campaign status': 'ENABLED'})

    @patch('agentic_dsta.tools.sa360.sa360_toolset.get_sheets_service', return_value=None)
    def test_get_campaign_details_no_service(self, mock_get_service):
        with self.assertRaisesRegex(RuntimeError, "Failed to get Google Sheets service"):
            sa360_toolset.get_campaign_details('123', 'sheet_id', 'sheet_name')

    @patch('agentic_dsta.tools.sa360.sa360_toolset.get_sheets_service')
    def test_get_campaign_details_not_found(self, mock_get_service):
        mock_service = MagicMock()
        mock_get_service.return_value = mock_service
        mock_sheet = MagicMock()
        mock_service.spreadsheets.return_value = mock_sheet
        
        mock_result = {
            'values': [
                ['Campaign ID', 'Name', 'Campaign status'],
                ['456', 'Campaign 2', 'PAUSED']
            ]
        }
        mock_sheet.values.return_value.get.return_value.execute.return_value = mock_result
        
        with self.assertRaisesRegex(ValueError, "Campaign with ID '123' not found"):
            sa360_toolset.get_campaign_details('123', 'sheet_id', 'sheet_name')

    @patch('agentic_dsta.tools.sa360.sa360_toolset.get_sheets_service')
    def test_get_campaign_details_exception(self, mock_get_service):
        mock_service = MagicMock()
        mock_get_service.return_value = mock_service
        mock_sheet = MagicMock()
        
        # Make execute raise HttpError
        mock_resp = MagicMock()
        mock_resp.status = 500
        error = HttpError(mock_resp, b'Error')
        mock_sheet.values.return_value.get.return_value.execute.side_effect = error
        mock_service.spreadsheets.return_value = mock_sheet
        
        with self.assertRaisesRegex(RuntimeError, "Failed to fetch campaign details"):
            sa360_toolset.get_campaign_details('123', 'sheet_id', 'sheet_name')

    @patch('agentic_dsta.tools.sa360.sa360_toolset.get_sheets_service')
    def test_update_campaign_property_success(self, mock_get_service):
        mock_service = MagicMock()
        mock_get_service.return_value = mock_service
        mock_sheet = MagicMock()
        mock_service.spreadsheets.return_value = mock_sheet
        
        mock_result = {
            'values': [
                ['Campaign ID', 'Name', 'Campaign status'],
                ['123', 'Campaign 1', 'ENABLED']
            ]
        }
        mock_sheet.values.return_value.get.return_value.execute.return_value = mock_result
        
        # update returns nothing/success dict?
        # The function `enable_campaign` calls `_update_campaign_property` which returns result from API
        # but `_update_campaign_property` helper calls `sheet.values().update().execute()`
        
        mock_update_res = {'updatedCells': 1}
        mock_sheet.values.return_value.update.return_value.execute.return_value = mock_update_res

        # We can test enable_campaign which uses _update_campaign_property
        result = sa360_toolset.enable_campaign('123', 'sheet_id', 'sheet_name')
        # The helper returns a success message dict
        expected_msg = {"success": "Campaign '123' Campaign status updated to 'ENABLED'."}
        self.assertEqual(result, expected_msg)
        
    @patch('agentic_dsta.tools.sa360.sa360_toolset.get_sheets_service')
    def test_enable_campaign_not_found(self, mock_get_service):
        mock_service = MagicMock()
        mock_get_service.return_value = mock_service
        mock_sheet = MagicMock()
        mock_service.spreadsheets.return_value = mock_sheet
        
        mock_result = {
            'values': [
                ['Campaign ID', 'Name', 'Campaign status'],
                ['456', 'Campaign 2', 'PAUSED']
            ]
        }
        mock_sheet.values.return_value.get.return_value.execute.return_value = mock_result
        
        with self.assertRaisesRegex(ValueError, "Campaign with ID '123' not found"):
            sa360_toolset.enable_campaign('123', 'sheet_id', 'sheet_name')

