# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""
Firestore Toolset - Read and write data from Google Cloud Firestore.
"""

import os
from typing import Any, Dict, List, Optional
from google.adk.tools.base_toolset import BaseToolset
from google.adk.tools.function_tool import FunctionTool
from google.cloud import firestore
from google.cloud.firestore_v1.base_query import FieldFilter


class FirestoreToolset(BaseToolset):
    """Toolset for interacting with Google Cloud Firestore."""

    def __init__(
        self,
        project_id: Optional[str] = None,
        database_id: str = "dsta-agentic-firestore"
    ):
        """
        Initialize Firestore toolset.

        Args:
            project_id: GCP project ID (defaults to GOOGLE_CLOUD_PROJECT env var)
            database_id: Firestore database ID (defaults to "(default)")
        """
        super().__init__()
        self._project_id = project_id or os.environ.get("GOOGLE_CLOUD_PROJECT")
        self._database_id = database_id
        self._client = None

    def _get_client(self) -> firestore.Client:
        """Get or create Firestore client."""
        if self._client is None:
            self._client = firestore.Client(
                project=self._project_id,
                database=self._database_id
            )
        return self._client

    async def get_tools(self, readonly_context: Optional[Any] = None) -> List[FunctionTool]:
        """Return all Firestore tools."""
        return [
            FunctionTool(func=self.get_document),
            FunctionTool(func=self.query_collection),
            FunctionTool(func=self.set_document),
            FunctionTool(func=self.delete_document),
            FunctionTool(func=self.list_collections),
        ]

    def get_document(
        self,
        collection: str,
        document_id: str
    ) -> Dict[str, Any]:
        """
        Get a single document from Firestore.

        Args:
            collection: Collection path (e.g., "users" or "users/user1/posts")
            document_id: Document ID

        Returns:
            Document data as dictionary
        """
        client = self._get_client()
        doc_ref = client.collection(collection).document(document_id)
        doc = doc_ref.get()

        if doc.exists:
            return {
                "id": doc.id,
                "data": doc.to_dict(),
                "exists": True
            }
        else:
            return {
                "id": document_id,
                "exists": False,
                "message": "Document not found"
            }

    def query_collection(
        self,
        collection: str,
        field: Optional[str] = None,
        operator: Optional[str] = None,
        value: Optional[str] = None,
        limit: int = 100
    ) -> Dict[str, Any]:
        """
        Query documents from a Firestore collection.

        Args:
            collection: Collection path
            field: Field name to filter on (optional)
            operator: Comparison operator: "==", "!=", "<", "<=", ">", ">=", "in", "not-in", "array-contains" (optional)
            value: Value to compare against (optional)
            limit: Maximum number of documents to return (default: 100)

        Returns:
            List of documents matching the query

        Examples:
            query_collection("users")  # Get all users
            query_collection("users", "age", ">", 18, limit=50)  # Get users over 18
            query_collection("products", "category", "==", "electronics")  # Get electronics
        """
        client = self._get_client()
        query = client.collection(collection)

        # Apply filter if provided
        if field and operator and value is not None:
            query = query.where(filter=FieldFilter(field, operator, value))

        # Apply limit
        query = query.limit(limit)

        # Execute query
        docs = query.stream()

        results = []
        for doc in docs:
            results.append({
                "id": doc.id,
                "data": doc.to_dict()
            })

        return {
            "collection": collection,
            "count": len(results),
            "documents": results
        }

    def set_document(
        self,
        collection: str,
        document_id: str,
        data: Dict[str, Any],
        merge: bool = False
    ) -> Dict[str, Any]:
        """
        Create or update a document in Firestore.

        Args:
            collection: Collection path
            document_id: Document ID
            data: Document data as dictionary
            merge: If True, merge with existing data; if False, overwrite (default: False)

        Returns:
            Confirmation of the operation
        """
        client = self._get_client()
        doc_ref = client.collection(collection).document(document_id)

        if merge:
            doc_ref.set(data, merge=True)
            operation = "merged"
        else:
            doc_ref.set(data)
            operation = "set"

        return {
            "success": True,
            "operation": operation,
            "collection": collection,
            "document_id": document_id
        }

    def delete_document(
        self,
        collection: str,
        document_id: str
    ) -> Dict[str, Any]:
        """
        Delete a document from Firestore.

        Args:
            collection: Collection path
            document_id: Document ID

        Returns:
            Confirmation of the deletion
        """
        client = self._get_client()
        doc_ref = client.collection(collection).document(document_id)
        doc_ref.delete()

        return {
            "success": True,
            "operation": "deleted",
            "collection": collection,
            "document_id": document_id
        }

    def list_collections(self) -> Dict[str, Any]:
        """
        List all root-level collections in Firestore.

        Returns:
            List of collection names
        """
        client = self._get_client()
        collections = client.collections()

        collection_names = [col.id for col in collections]

        return {
            "count": len(collection_names),
            "collections": collection_names
        }
