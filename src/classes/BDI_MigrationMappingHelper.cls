/*
    Copyright (c) 2017, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2019
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Helper class that supports BDI_MigrationMappingUtility and
* enables mocking of test data.
*/
public class BDI_MigrationMappingHelper {

    /**
     * @description Go through all fields in Data Import object and collect relevant help text mappings
     * @return A collection of help text field names mapped to an instance of MappingDetail which holds
     * relevant values for building
     * the corresponding Metadata Type record (i.e. Source Object Name, Target Object Name, Target Field
     * API Name, etc)
     */
    public Map<String, BDI_HelpTextCMT.MappingDetail> getAllMappedHelpTextFields() {

        Map<String, BDI_HelpTextCMT.MappingDetail> helpTextFieldMap =
                new Map<String, BDI_HelpTextCMT.MappingDetail>();

        Map<String, BDI_HelpTextCMT.ImportStatusAndLookupParts> importStatusAndLookupMap =
                new Map<String, BDI_HelpTextCMT.ImportStatusAndLookupParts>();

        Map<String, Schema.DescribeFieldResult> allDFRs =
                UTIL_Describe.getAllFieldsDescribe(UTIL_Namespace.StrAllNSPrefix('DataImport__c'));


        for (String dataImportFieldName : allDFRs.keySet()) {

            // check if field is importstatus or imported
            Boolean isImportStatus = dataImportFieldName.contains('importstatus');
            Boolean isImportLookup = dataImportFieldName.contains('imported');

            if (isImportStatus || isImportLookup) {
                // Pass help text values to a new instance of ImportStatusAndLookupParts wrapper class
                BDI_HelpTextCMT.ImportStatusAndLookupParts importRelatedField =
                        getImportStatusAndLookupParts(dataImportFieldName, importStatusAndLookupMap);

                importStatusAndLookupMap.put(importRelatedField.objectName, importRelatedField);

                // Found an import status or import lookup field, no help text value so continue
                continue;
            }

            DescribeFieldResult sourceField = allDFRS.get(dataImportFieldName);
            String helpText = sourceField.getInlineHelpText();
            Boolean helpTextIsUsable = String.isNotBlank(helpText) && !helpText.contains(' ');

            if (helpTextIsUsable) {
                BDI_HelpTextCMT.HelpTextParts parts = new BDI_HelpTextCMT.HelpTextParts(helpText);
                Boolean fieldNameIsUsable = String.isNotBlank(parts.fieldName);
                Boolean objectNameIsUsable = String.isNotBlank(parts.objectName);

                // Check if the current help text mapping's object and field name are usable
                if (fieldNameIsUsable && objectNameIsUsable) {

                    // Pass help text values to a new instance of MappingDetail wrapper class
                    BDI_HelpTextCMT.MappingDetail newMappingDetail =
                            new BDI_HelpTextCMT.MappingDetail(parts.objectName,
                                    sourceField.Label,
                                    parts.objectAPIName,parts.fieldName, null, null);

                    helpTextFieldMap.put(sourceField.Name, newMappingDetail);

                    // Remove from map once mapped
                    allDFRS.remove(dataImportFieldName);
                }
            }
        }

        // Add import status and import lookup field values
        for (String key : helpTextFieldMap.keySet()) {
            BDI_HelpTextCMT.MappingDetail mappingDetail = helpTextFieldMap.get(key);
            setImportStatusAndLookupFields(mappingDetail, importStatusAndLookupMap);
        }

        System.debug(LoggingLevel.ERROR, '*** variable value helpTextFieldMap: ' + helpTextFieldMap);
        return helpTextFieldMap;
    }

    /**
     * @description Set import lookup and import status fields on the MappingDetail instance
     * @param  mappingDetail Instance of MappingDetail where fields are to be set
     * @param  importStatusAndLookupMap Map holding the field values to be set to MappingDetail
     */
    private void setImportStatusAndLookupFields(BDI_HelpTextCMT.MappingDetail mappingDetail,
            Map<String, BDI_HelpTextCMT.ImportStatusAndLookupParts> importStatusAndLookupMap) {

        BDI_HelpTextCMT.ImportStatusAndLookupParts importStatusAndLookupParts =
                importStatusAndLookupMap.get(mappingDetail.dataImportObjectName);

        mappingDetail.importedRecordField = importStatusAndLookupParts.importLookupFieldName;
        mappingDetail.importedRecordStatusField = importStatusAndLookupParts.importStatusFieldName;
    }

    /**
     * @description Builds an instance of ImportStatusAndLookupParts which holds an object name,
     *              ImportedLookup__c and ImportStatus__c field names
     * @param dataImportFieldName Name of a Data Import field
     * @param importStatusAndLookupMap List of ImportStatusAndLookupParts instances
     * @return instance of ImportStatusAndLookupParts
     */
    private BDI_HelpTextCMT.ImportStatusAndLookupParts getImportStatusAndLookupParts(String dataImportFieldName,
            Map<String, BDI_HelpTextCMT.ImportStatusAndLookupParts> importStatusAndLookupMap) {

        // Create new instance of ImportStatusAndLookupParts
        BDI_HelpTextCMT.ImportStatusAndLookupParts importRelatedField =
                new BDI_HelpTextCMT.ImportStatusAndLookupParts(dataImportFieldName);

        // Check if there is already an existing and matching instance of ImportStatusAndLookupParts
        BDI_HelpTextCMT.ImportStatusAndLookupParts exists =
                importStatusAndLookupMap.get(importRelatedField.objectName);

        // If one exists, reset instance with newly added field
        if (exists != null) {
            importRelatedField = new BDI_HelpTextCMT.ImportStatusAndLookupParts(exists, dataImportFieldName);
        }

        return importRelatedField;
    }
}