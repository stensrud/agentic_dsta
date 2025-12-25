import unittest
from unittest import mock
import os

# Mock uvicorn and get_fast_api_app at the class level to affect imports
@mock.patch('agentic_dsta.main.uvicorn')
@mock.patch('google.adk.cli.fast_api.get_fast_api_app') # Correct target
class TestMain(unittest.TestCase):

    @mock.patch.dict(os.environ, {'PORT': '8000'})
    def test_main(self, mock_get_fast_api_app, mock_uvicorn):
        import agentic_dsta.main

        mock_app = mock.MagicMock()
        with mock.patch.object(agentic_dsta.main, 'app', mock_app):
            agentic_dsta.main.main()

        mock_uvicorn.run.assert_called_once_with(mock_app, host='0.0.0.0', port=8000)

    @mock.patch.dict(os.environ, {}, clear=True)
    def test_main_default_port(self, mock_get_fast_api_app, mock_uvicorn):
        import agentic_dsta.main

        mock_app = mock.MagicMock()
        with mock.patch.object(agentic_dsta.main, 'app', mock_app):
            agentic_dsta.main.main()

        mock_uvicorn.run.assert_called_once_with(mock_app, host='0.0.0.0', port=8080)

if __name__ == '__main__':
    unittest.main()
