/**
 * @Component Name SecurityUtils
 * @Created Date   April 3, 2020
 * @Description    Utility class for checking FLS/CRUD.NOTE: all "check" methods will throw a SecurityException
 *                        (or subclass) if the user does not have the proper security granted .
 * @Test Class     SecurityUtils_Test with code coverage of 95%
 * @Author         Gaurav Trivedi
 * @Group
 * @Last Modified By Gaurav Trivedi
 * @Last Modified On 4/7/2020, 6:44:58 PM
 * @Modification Log
 * **********************************************************************************************************************
 *										Modification Log
 * **********************************************************************************************************************
 *  Name				|	Version		|		Date		|					Discription
 * **********************************************************************************************************************
 *	Gaurav Trivedi      |       1.0     |	April 3, 2020	|	Initial Draft
 * **********************************************************************************************************************
 *  NOTE DO NOT CHANGE THIS CLASS
 */
public with sharing class SecurityUtils {
    /**
     * If set to true all check methods will always return void, and never throw exceptions.
     * This should really only be set to true if an app-wide setting to disable in-apex
     * FLS and CRUD checks exists and is enabled.
     * Per security best practices setting BYPASS should be an a opt-in, and not the default behavior.
     **/
    public static boolean bypassInternalFLSandCURD = false;
    @testVisible
    private Enum OperationType { CREATE, READ, MODIFY, DEL } //UPDATE and DELETE are reserved words

    /**
     * @ClassName   SecurityException
     * @description SecurityException is never be thrown directly by SecurityUtils, instead all
     *                forms of CRUD and FLD violations throw subclasses of it.It is provided as a conveneience
     *                in the event you wish to handle CRUD and FLS violations the same way (e.g.die and display an error)
     */
    public virtual class SecurityException extends Exception {
        protected OperationType typeOfOperation;
        protected Schema.SObjectType objectType;
    }

    /**
     * @ClassName   CrudException
     * @description CrudException represents a running user 's lack of read/create/update/delete access at a profile (or permission set)
     *                level. Sharing and field level security issues will never cause this.
     */
    public class CrudException extends SecurityException {

        private CrudException(OperationType operation, Schema.SObjectType objectType){
            this.typeOfOperation = operation;
            this.objectType = objectType;
            if(operation == OperationType.CREATE) {
                this.setMessage(System.Label.security_error_object_not_insertable);
            }else if(operation == OperationType.READ) {
                this.setMessage(System.Label.security_error_object_not_readable);
            }else if(operation == OperationType.MODIFY) {
                this.setMessage(System.Label.security_error_object_not_updateable);
            }else if(operation == OperationType.DEL) {
                this.setMessage(System.Label.security_error_object_not_deletable);
            }
            this.setMessage(String.format(this.getMessage(), new List<String> { objectType.getDescribe().getName()}));
        }
    }

    /**
     * @ClassName   FlsException
     * @description FlsException represents a running user 's lack of field level security to a specific field at a profile (or permission set) level
     *                Sharing and CRUD security issues will never cause this to be thrown.
     */
    public class FlsException extends SecurityException {
        private Schema.SObjectField tokenField;

        private FlsException(OperationType operation, Schema.SObjectType objectType, Schema.SObjectField fieldToken){
            this.typeOfOperation = operation;
            this.objectType = objectType;
            this.tokenField = fieldToken;
            if(operation == OperationType.CREATE) {
                this.setMessage(System.Label.security_error_field_not_insertable);
            }else if(operation == OperationType.READ) {
                this.setMessage(System.Label.security_error_field_not_readable);
            }else if(operation == OperationType.MODIFY) {
                this.setMessage(System.Label.security_error_field_not_updateable);
            }
            this.setMessage(String.format(this.getMessage(),new List<String> {objectType.getDescribe().getName(),fieldToken.getDescribe().getName()}));
        }
    }
    /**
     * Check{Insert,Read,Update} methods check both FLS and CRUD
     **/

    /**
     * @function    checkInsert
     * @description Checks both insert FLS and CRUD for the specified object type and fields.
     * @exception   FlsException if the running user does not have insert rights to any fields in {@code fieldNames}.
     * @exception   CrudException if the running user does not have insert rights to {@code objType}
     * @param      objType object name as the type of {SObjectType}
     * @param      fieldNames API name of all fields in a list as a string
     * @example
     * SecurityUtils.checkInsert (
     *  Account.SObjectType,
     *  new List<String> {
     *      'Name',
     *      'ParentId',
     *      'ownerId'
     *  }
     */
    public static void checkInsert(SObjectType objType, List<String> fieldNames){
        checkObjectIsInsertable(objType);
        for (String fieldName : fieldNames) {
            checkFieldIsInsertable(objType, fieldName);
        }
    }

    /**
     * @function    checkInsert
     * @description Identical to {@link # checkInsert(SObjectType,List<String>)}, except with SObjectField instead of String field references .
     * @exception   FlsException if the running user does not have insert rights to any fields in {@code fieldTokens}.
     * @exception   CrudException if the running user does not have insert rights to {@code objType}
     * @param       objType object name as the type of {SObjectType}
     * @param       fieldTokens API name of all fields in a list as a SObjectField
     * @example
     * SecurityUtils.checkInsert (
     *  Account.SObjectType,
     *  new List<Schema.SObjectField> {
     *      Account.SObjectType.fields.Name,
     *      Account.SObjectType.fields.ParentId,
     *      Account.SObjectType.fields.ownerId
     *  }
     */
    public static void checkInsert(SObjectType objType, List<SObjectField> fieldTokens){
        checkObjectIsInsertable(objType);
        for (SObjectField fieldToken : fieldTokens) {
            checkFieldIsInsertable(objType, fieldToken);
        }
    }

    /**
     * @function    checkRead
     * @description Checks both read FLS and CRUD for the specified object type and fields .
     * @exception   FlsException if the running user does not have insert rights to any fields in {@code fieldNames}.
     * @exception   CrudException if the running user does not have insert rights to {@code objType}
     * @param      objType object name as the type of {SObjectType}
     * @param      fieldNames API name of all fields in a list as a string
     * @example
     * SecurityUtils.checkRead (
     *  Account.SObjectType,
     *  new List<String> {
     *      'Name',
     *      'ParentId',
     *      'ownerId'
     *  }
     */
    public static void checkRead(SObjectType objType, List<String> fieldNames){
        checkObjectIsReadable(objType);
        for (String fieldName : fieldNames) {
            checkFieldIsReadable(objType, fieldName);
        }
    }

    /**
     * @function    checkRead
     * @description Identical to {@link # checkRead(SObjectType,List<String>)}, except with SObjectField instead of String field references .
     * @exception   FlsException if the running user does not have read rights to any fields in {@code fieldTokens}.
     * @exception   CrudException if the running user does not have read rights to {@code objType}
     * @param       objType object name as the type of {SObjectType}
     * @param       fieldTokens API name of all fields in a list as a SObjectField
     * @example
     * SecurityUtils.checkRead (
     *  Account.SObjectType,
     *  new List<Schema.SObjectField> {
     *      Account.SObjectType.fields.Name,
     *      Account.SObjectType.fields.ParentId,
     *      Account.SObjectType.fields.ownerId
     *  }
     */
    public static void checkRead(SObjectType objType, List<SObjectField> fieldTokens){
        checkObjectIsReadable(objType);
        for (SObjectField fieldToken : fieldTokens) {
            checkFieldIsReadable(objType, fieldToken);
        }
    }

    /**
     * @function    checkUpdate
     * @description Checks both update FLS and CRUD for the specified object type and fields .
     * @exception   FlsException if the running user does not have read rights to any fields in {@code fieldTokens}.
     * @exception   CrudException if the running user does not have read rights to {@code objType}
     * @param      objType object name as the type of {SObjectType}
     * @param      fieldNames API name of all fields in a list as a string
     * @example
     * SecurityUtils.checkUpdate (
     *  Account.SObjectType,
     *  new List<Schema.SObjectField> {
     *      'Name',
     *      'ParentId',
     *      'ownerId'
     *  }
     */
    public static void checkUpdate(SObjectType objType, List<String> fieldNames){
        checkObjectIsUpdateable(objType);
        for (String fieldName : fieldNames) {
            checkFieldIsUpdateable(objType, fieldName);
        }
    }

    /**
     * @function    checkUpdate
     * @description Identical to {@link # checkUpdate(SObjectType,List<String>)}, except with SObjectField instead of String field references.
     * @exception  FlsException if the running user does not have update rights to any fields in {@code fieldTokens} .
     * @exception  CrudException if the running user does not have update rights to {@code objType}
     * @param       objType object name as the type of {SObjectType}
     * @param       fieldTokens API name of all fields in a list as a SObjectField
     * @example
     * SecurityUtils.checkUpdate (
     *  Account.SObjectType,
     *  new List<Schema.SObjectField> {
     *      Account.SObjectType.fields.Name,
     *      Account.SObjectType.fields.ParentId,
     *      Account.SObjectType.fields.ownerId
     * }
     */
    public static void checkUpdate(SObjectType objType, List<SObjectField> fieldTokens){
        checkObjectIsUpdateable(objType);
        for (SObjectField fieldToken : fieldTokens) {
            checkFieldIsUpdateable(objType, fieldToken);
        }
    }
    /**
     * CheckFieldIs* method check only FLS
     **/

    /**
     * @function    checkFieldIsInsertable
     * @description Checks insert field level security only (no CRUD) for the specified fields on {@code objType}
     * @exception  FlsException if the running user does not have insert rights to the {@code fieldName} field.
     * @param      objType object name as the type of {SObjectType}
     * @param      fieldName API name of the field as string
     * @example
     * SecurityUtils.checkFieldIsInsertable(Account.SObjectType, 'Name');
     */
    public static void checkFieldIsInsertable(SObjectType objType, String fieldName){
        checkFieldIsInsertable(objType, SObjectDescribe.getDescribe(objType).getField(fieldName));
    }

    /**
     * @function    checkFieldIsInsertable
     * @description Identical to {@link # checkFieldIsInsertable(SObjectType,String)}, except with SObjectField instead of String field reference.
     * @exception  FlsException if the running user does not have insert rights to the {@code fieldName} field.
     * @param      objType object name as the type of {SObjectType}
     * @param      fieldToken API name of the field as {SObjectField}
     * @example
     * SecurityUtils.checkFieldIsInsertable(Account.SObjectType, Account.SObjectType.fields.Name);
     */
    public static void checkFieldIsInsertable(SObjectType objType, SObjectField fieldToken){
        checkFieldIsInsertable(objType, fieldToken.getDescribe());
    }

    /**
     * @function    checkFieldIsInsertable
     * @description Identical to {@link # checkFieldIsInsertable(SObjectType,String)}, except with DescribeFieldResult instead of String field reference.
     * @exception  FlsException if the running user does not have insert rights to the {@code fieldName} field.
     * @param      objType object name as the type of {SObjectType}
     * @param      fieldDescribe with data type {DescribeFieldResult}
     */
    public static void checkFieldIsInsertable(SObjectType objType, DescribeFieldResult fieldDescribe){
        if (bypassInternalFLSandCURD) {
            return;
        }
        if (!fieldDescribe.isCreateable()) {
            throw new FlsException(OperationType.CREATE, objType, fieldDescribe.getSObjectField());
        }
    }

    /**
     * @function    checkFieldIsReadable
     * @description Checks read field level security only (no CRUD) for the specified fields on {@code objType}
     * @exception  FlsException if the running user does not have insert rights to the {@code fieldName} field.
     * @param      objType object name as the type of {SObjectType}
     * @param      fieldName API name of Field as String
     * @example
     * SecurityUtils.checkFieldIsReadable(Account.SObjectType, 'Name');
     */
    public static void checkFieldIsReadable(SObjectType objType, String fieldName){
        checkFieldIsReadable(objType, SObjectDescribe.getDescribe(objType).getField(fieldName));
    }

    /**
     * @function    checkFieldIsReadable
     * @description Identical to {@link # checkFieldIsReadable(SObjectType,String)}, except with SObjectField instead of String field reference .
     * @exception  FlsException if the running user does not have insert rights to the {@code fieldName} field.
     * @param      objType object name as the type of {SObjectType}
     * @param      fieldToken API name of the field as {SObjectField}
     * @example
     * SecurityUtils.checkFieldIsReadable(Account.SObjectType, Account.SObjectType.fields.Name);
     */
    public static void checkFieldIsReadable(SObjectType objType, SObjectField fieldToken){
        checkFieldIsReadable(objType, fieldToken.getDescribe());
    }

    /**
     * @function    checkFieldIsReadable
     * @description Identical to {@link # checkFieldIsReadable(SObjectType,String)}, except with DescribeFieldResult instead of String field reference.
     * @exception  FlsException if the running user does not have insert rights to the {@code fieldName} field.
     * @param      objType object name as the type of {SObjectType}
     * @param      fieldDescribe
     */
    public static void checkFieldIsReadable(SObjectType objType, DescribeFieldResult fieldDescribe){
        if (bypassInternalFLSandCURD) {
            return;
        }
        if (!fieldDescribe.isAccessible()) {
            throw new FlsException(OperationType.READ, objType, fieldDescribe.getSObjectField());
        }
    }

    /**
     * @function    checkFieldIsUpdateable
     * @description Checks update field level security only (no CRUD) for the specified fields on {@code objType}
     * @exception  FlsException if the running user does not have insert rights to the {@code fieldName} field.
     * @param      objType object name as the type of {SObjectType}
     * @param      fieldName API name of Field as String
     * @example
     * SecurityUtils.checkFieldIsUpdateable(Account.SObjectType, 'Name');
     */
    public static void checkFieldIsUpdateable(SObjectType objType, String fieldName){
        checkFieldIsUpdateable(objType, SObjectDescribe.getDescribe(objType).getField(fieldName));
    }

    /**
     * @function    checkFieldIsUpdateable
     * @description Identical to {@link # checkFieldIsUpdateable(SObjectType,String)}, except with SObjectField instead of String field reference.
     * @exception  FlsException if the running user does not have insert rights to the {@code fieldName} field.
     * @param      objType object name as the type of {SObjectType}
     * @param      fieldToken {SObjectField}
     * @example
     * SecurityUtils.checkFieldIsUpdateable(Account.SObjectType, Account.SObjectType.fields.Name);
     */
    public static void checkFieldIsUpdateable(SObjectType objType, SObjectField fieldToken){
        checkFieldIsUpdateable(objType, fieldToken.getDescribe());
    }

    /**
     * @function    checkFieldIsUpdateable
     * @description Identical to {@link # checkFieldIsUpdateable(SObjectType,String)}, except with DescribeFieldResult instead of String field reference.
     * @exception  FlsException if the running user does not have insert rights to the {@code fieldName} field.
     * @param      objType object name as the type of {SObjectType}
     * @param      fieldDescribe {DescribeFieldResult}
     */
    public static void checkFieldIsUpdateable(SObjectType objType, DescribeFieldResult fieldDescribe){
        if (bypassInternalFLSandCURD) {
            return;
        }
        if (!fieldDescribe.isUpdateable()) {
            throw new FlsException(OperationType.MODIFY, objType, fieldDescribe.getSObjectField());
        }
    }

    /**
     * CheckObjectIs* methods check only CRUD
     **/

    /**
     * @function    checkObjectIsInsertable
     * @description Checks insert CRUD for the specified object type.
     * @exception  CrudException if the running uder does not have insert rights to the {@code objType} SObject .
     * @param      objType object name as the type of {SObjectType}
     * @example
     * SecurityUtils.checkObjectIsInsertable(Account.SObjectType);
     */
    public static void checkObjectIsInsertable(SObjectType objType){
        if (bypassInternalFLSandCURD) {
            return;
        }
        if (!objType.getDescribe().isCreateable()) {
            throw new CrudException(OperationType.CREATE, objType);
        }
    }

    /**
     * @function    checkObjectIsReadable
     * @description Checks read CRUD for the specified object type.
     * @exception  CrudException if the running uder does not have insert rights to the {@code objType} SObject .
     * @param      objType object name as the type of {SObjectType}
     * @example
     * SecurityUtils.checkObjectIsReadable(Account.SObjectType);
     */
    public static void checkObjectIsReadable(SObjectType objType){
        if (bypassInternalFLSandCURD) {
            return;
        }
        if (!objType.getDescribe().isAccessible()) {
            throw new CrudException(OperationType.READ, objType);
        }
    }

    /**
     * @function    checkObjectIsUpdateable
     * @description Checks update CRUD for the specified object type .
     * @exception  CrudException if the running uder does not have insert rights to the {@code objType} SObject .
     * @param      objType object name as the type of {SObjectType}
     * @example
     * SecurityUtils.checkObjectIsUpdateable(Account.SObjectType);
     */
    public static void checkObjectIsUpdateable(SObjectType objType){
        if (bypassInternalFLSandCURD) {
            return;
        }
        if (!objType.getDescribe().isUpdateable()) {
            throw new CrudException(OperationType.MODIFY, objType);
        }
    }

    /**
     * @function    checkObjectIsDeletable
     * @description Checks delete CRUD for the specified object type.
     * @exception  CrudException if the running uder does not have insert rights to the {@code objType} SObject .
     * @param      objType object name as the type of {SObjectType}
     * @example
     * SecurityUtils.checkObjectIsDeletable(Account.SObjectType);
     */
    public static void checkObjectIsDeletable(SObjectType objType){
        if (bypassInternalFLSandCURD) {
            return;
        }
        if (!objType.getDescribe().isDeletable()) {
            throw new CrudException(OperationType.DEL, objType);
        }
    }
}