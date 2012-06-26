<cfset application.beanFactory = createObject("component", "coldspring.beans.DefaultXMLBeanFactory") />
<cfset application.beanFactory.loadBeans('/taffy/examples/ParentApplication/config/coldspring.xml') />
