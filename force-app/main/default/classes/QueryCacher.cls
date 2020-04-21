/**
 * @Component Name      QueryCacher
 * @Created Date        April 2, 2020
 * @Description         This class is for generating queries and helping to cache them in the transation for repurposing.
 * @Test Class          QueryCacher_Test with code coverage of 100%
 * @Author              Gaurav Trivedi
 * @Group
 * @Last Modified By    Gaurav Trivedi
 * @Last Modified On    4/3/2020, 12:40:56 PM
 * @Modification Log
 * **********************************************************************************************************************
 *										Modification Log
 * **********************************************************************************************************************
 *  Name				|	Version		|		Date		|					Discription
 * **********************************************************************************************************************
 *	Gaurav Trivedi      |       1.0     |	Aprit 2, 2020	|	Initial Draft
 * **********************************************************************************************************************
 * NOTE: DO NOT CHANGE THIS CLASS UNTIL WE WANT TO ADD COMMON FUNCTIONALITY AROUNG QUERIES
 */
public with sharing class QueryCacher {
    @TestVisible
    private static final Map<String, Map<Id, SObject> > QUERY_RESULT_MAP = new Map<String, Map<Id, SObject> > ();
    @TestVisible
    private static final Map<String, List <SObject> > LIST_QUERY_RESULT_MAP = new Map<String, List<SObject> > ();
    /**
     * @function    fetchObjects
     * @description use to create a map of query results by making database interaction, if data is already exist then return
     *              the old queried data from cached variable.
     * @param       queryString the SOQL query string
     * @return      returns the Map of sObjects with data set
     * @example
     * String contactQueryString = 'SELECT Id, Name FROM Contact';
     * Map<String, Contact> contactMap = (Map<String, Contact>) JSON.deserialize(JSON.serialize(QueryCacher.fetchObjects(contactQueryString)), Map<String, Contact>.class);
     */
    public static Map <Id, SObject> fetchObjects (String queryString){
        Map <Id, SObject> resultsMap = QUERY_RESULT_MAP.get (queryString);
        if (resultsMap == null) {
            resultsMap = new Map <Id, SObject> ();
            for (SObject o : Database.query(queryString)) {
                resultsMap.put (o.Id, o);
            }
            QUERY_RESULT_MAP.put (queryString, resultsMap);
        }
        return resultsMap;
    }
    /**
     * @function    getListOfRecords
     * @description use to get the list of records by making database interaction, if data is already exist then return
     *              the old queried data from cached variable.
     * @param       queryString the SOQL query string
     * @return      return the list of records
     * @example
     * String contactQueryString = 'SELECT Id, Name FROM Contact';
     * List<Contact> contactList = QueryCacher.getListOfRecords(contactQueryString);
     */
    public static List <SObject> getListOfRecords (String queryString){
        List <SObject> resultList = LIST_QUERY_RESULT_MAP.get (queryString);
        if (resultList == null) {
            resultList = Database.query(queryString);
            LIST_QUERY_RESULT_MAP.put (queryString, resultList);
        }
        return resultList;
    }

    /**
     * @function    clearCache
     * @description remove all the queried result from the cached variables
     */
    public static void clearCache(){
        LIST_QUERY_RESULT_MAP.clear();
        QUERY_RESULT_MAP.clear();
    }

    /**
     * @function    clearCacheMapOfList
     * @description remove cached query result from Map of List of object
     * @example
     * Set<Id> accountIdSet = new Set<Id>();
     * String contactQueryString;
     * String accountQueryString = 'SELECT Id, Name FROM Account';
     * for(Account account: (List<Account>) QueryCacher.getListOfRecords(accountQueryString)) {
     *     if(account.Name <> null){
     *          accountIdSet.add(account.Id);
     *      }
     *  }
     *  if(!accountIdSet.isEmpty()){
     *      contactQueryString = 'SELECT Id, Name FROM Contact WHERE Id IN '+ QueryCacher.getQueryString(accountIdSet);
     *      List<Contact> contactList = QueryCacher.getListOfRecords(contactQueryString);
     * }
     * Do Some processing and after that if Contact Map is not required then remove the query result
     * QueryCacher.clearCacheMapOfList(contactQueryString);
     */
    public static void clearCacheMapOfList(String queryString){
        LIST_QUERY_RESULT_MAP.remove(queryString);
    }
    /**
     * @function    clearCacheMapOfMap
     * @description remove cached query result from Map of Map of object
     * @example
     * Set<Id> accountIdSet = new Set<Id>();
     * String contactQueryString;
     * String opportunityQueryString;
     * for(Account account: Trigger.new){
     *     if(account.Name <> null){
     *          accountIdSet.add(account.Id);
     *      }
     *  }
     *  if(!accountIdSet.isEmpty()){
     *      contactQueryString = 'SELECT Id, Name FROM Contact WHERE Id IN '+ QueryCacher.getQueryString(accountIdSet);
     *      Map<String, Contact> contactMap = (Map<String, Contact>) JSON.deserialize(JSON.serialize(QueryCacher.fetchObjects(contactQueryString)), Map<String, Contact>.class);
     *      opportunityQueryString = 'SELECT Id, Name FROM Opportunity WHERE Id IN '+ QueryCacher.getQueryString(accountIdSet);
     *      List<Opportunity> opportunityList = QueryCacher.fetchObjects(contactQueryString).values();
     * }
     * Do Some processing and after that if Contact Map is not required then remove the query result
     * QueryCacher.clearCacheMapOfMap(contactQueryString);
     */
    public static void clearCacheMapOfMap(String queryString){
        QUERY_RESULT_MAP.remove(queryString);
    }
    /**
     * @function    getQueryString
     * @description Getting where clause for querying the data from Salesforce only with Set of String which is used
     *              in IN clause
     * @param       stringSet
     * @return      query string
     */
    public static String getQueryString (Set <String> stringSet){
        return getQueryString(null, stringSet);
    }

    /**
     * @function    getQueryString
     * @description Getting where clause for querying the data from Salesforce only with Set of Id which is used
     *              in IN clause
     * @param       idSet Set of id's
     * @return      query string
     */
    public static String getQueryString (Set <Id> idSet){
        return getQueryString(idSet, null);
    }
    /**
     * @function    getQueryString
     * @description Generating  where clause for querying the data from Salesforce with Set of Ids or Set of String
     * @param       idSet
     * @param       stringSet
     * @return      query string
     * @example
     * Set<Id> accountIdSet = new Set<Id>();
     * String accountQueryString = 'SELECT Id, Name FROM Account';
     * for(Account account: (List<Account>) QueryCacher.fetchObjects(accountQueryString).values()) {
     *     if(account.Name <> null){
     *          accountIdSet.add(account.Id);
     *      }
     *  }
     *  if(!accountIdSet.isEmpty()){
     *      String contactQueryString = 'SELECT Id, Name FROM Contact WHERE Id IN '+ QueryCacher.getQueryString(accountIdSet);
     *      List<Contact> contactList = QueryCacher.getListOfRecords(contactQueryString);
     *  }
     */
    private static String getQueryString(Set<Id> idSet, Set<String> stringSet){
        String queryString = '(';
        for(String parameter: idSet <> null ? (Set<String>)JSON.deserialize(JSON.serialize(idSet), Set<String>.class) : stringSet) {
            if(String.isNotBlank(parameter)) {
                if(queryString <> '(') {
                    queryString += ', ';
                }
                queryString += '\'' + String.escapeSingleQuotes (parameter) + '\'';
            }
        }
        queryString += ')';
        return queryString;
    }
}