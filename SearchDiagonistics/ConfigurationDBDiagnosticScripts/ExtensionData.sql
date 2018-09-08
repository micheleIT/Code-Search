/*
This script gets the extension configuration and install status.
*/

SELECT ParentPath, ChildItem, RegValue
FROM tbl_RegistryItems
where PartitionId > 0 and
(ParentPath like '%IsExtensionOperationInProgress%'
or ChildItem like '%IsCollectionIndexed%')
