<%@page import="java.util.*,
				blackboard.platform.*,
				blackboard.base.*,
				blackboard.data.*,
                blackboard.data.user.*,
				blackboard.data.role.*,
                blackboard.persist.*,
                blackboard.persist.user.*,
				blackboard.persist.role.*"
        errorPage="/error.jsp"                
%>

<%@ taglib uri="/bbData" prefix="bbData"%>                
<%@ taglib uri="/bbUI" prefix="bbUI"%>
<style type="text/css">
<!--
.style7 {font-family: Arial; font-size: 14px; }
-->
</style>

<bbData:context id="ctx">
<bbUI:docTemplate title="Search Users by Institution Role">
<bbUI:breadcrumbBar environment="SYS_ADMIN" handle="admin_main" isContent="true">
 <bbUI:breadcrumb>Institution Role Search</bbUI:breadcrumb>
</bbUI:breadcrumbBar>

<bbUI:titleBar iconUrl="/images/ci/icons/user3_u.gif">Search Users by Institiution Role</bbUI:titleBar>
<%
// we want to get all possible institution roles from the database

	// create a persistence manager - needed if we want to use loaders or persistersi n blakcboard
	BbPersistenceManager bbPm = BbServiceManager.getPersistenceService().getDbPersistenceManager();
	
	//create a database loader for portal roles
	PortalRoleDbLoader loader = (PortalRoleDbLoader) bbPm.getLoader(PortalRoleDbLoader.TYPE);
	
	UserDbLoader userloader = (UserDbLoader) bbPm.getLoader(UserDbLoader.TYPE);
	//gives us a list of all available portal roles objects in the database
	BbList roleList = loader.loadAll();
	
	// we want to find how many people have each role
	Iterator iter = roleList.iterator();
	/*
	BbList track= null;
	while(iter.hasNext())
	{
	 	PortalRole currentRole = (PortalRole)iter.next();
	 	// find out how many people have the role
		track = userloader.loadByPrimaryPortalRoleId(currentRole.getId());
		// if nobody has the role - we want to remove that role from the list
		if (track.size() < 1){
			iter.remove();		
		}
	} // now rolelist contains only active roles (there's somebody in the system that has that role)
	*/
	
%>
<table width="950" height="41" border="0" cellpadding="0" bordercolor="#999999" bgcolor="#FFFFFF">
  <tr><form action="search.jsp" method="post" name="searchform" id="searchform">
    <td width="394" valign="middle" nowrap bordercolor="#FFFFFF" bgcolor="#FFFFFF"><span class="style7">
	    <strong>Search</strong>	    
	    <select name="attribute" id="attribute">
            <option value="1" <% if(request.getParameter("attribute")!=null && request.getParameter("attribute").equals("1"))out.print("selected");%>>Username</option>
            <option value="2" <% if(request.getParameter("attribute")!=null && request.getParameter("attribute").equals("2"))out.print("selected");%>>First Name</option>
            <option value="3" <% if(request.getParameter("attribute")!=null && request.getParameter("attribute").equals("3"))out.print("selected");%>>Last Name</option>
            <option value="4" <% if(request.getParameter("attribute")!=null && request.getParameter("attribute").equals("4"))out.print("selected");%>>Email</option>
        </select>
          <select name="method" id="method">
            <option value="1" <% if(request.getParameter("method")!=null && request.getParameter("method").equals("1"))out.print("selected");%>>Contains</option>
            <option value="2" <% if(request.getParameter("method")!=null && request.getParameter("method").equals("2"))out.print("selected");%>>Starts with</option>
            <option value="3" <% if(request.getParameter("method")!=null && request.getParameter("method").equals("3"))out.print("selected");%>>Equal to</option>
          </select> 
          <input name="searchparam" type="text" id="searchparam" value="<% if(request.getParameter("searchparam")!=null)out.print(request.getParameter("searchparam"));%>">
	  </span></td>
		  <td width="196" align="left" valign="middle" nowrap bordercolor="#FFFFFF" bgcolor="#FFFFFF"><span class="style7">
		  <input type="IMAGE" name="commit" src="/images/ci/misc/go_btn_off.gif" alt="Go" border=0 onClick="document.searchform.submit()">
		  <input type="hidden" name="process" value="1">
	  </td>
  <td width="352" valign="middle" bordercolor="#FFFFFF" bgcolor="#FFFFFF"><div align="right" class="style7"><strong>Institution Role</strong>        
	<select name="instrole">
	<% 
		GenericFieldComparator comparator = new GenericFieldComparator(BaseComparator.ASCENDING,"getRoleName", PortalRole.class);
    	Collections.sort(roleList,comparator);
		iter = roleList.iterator();
		while(iter.hasNext())
		{
			PortalRole role = (PortalRole)iter.next();
			if(request.getParameter("instrole")!=null && request.getParameter("instrole").equals(role.getId().toExternalString()))
			{
				out.print("<option value=\""+role.getId().toExternalString()+"\" selected>"+role.getRoleName()+"</option>");
			}
			else{
				out.print("<option value=\""+role.getId().toExternalString()+"\">"+role.getRoleName()+"</option>");
			}
		}
	%>
        </select>
    </div></td></form>
  </tr>
</table>
<%
//process the results from the form
BbList results = new BbList();
if(request.getParameter("process")!=null)
{
//form has been submitted
	String sparam = request.getParameter("searchparam");
	if(sparam==null)sparam="";
//if the searchparam is empty: we load all users that have the selected role and ....
	/*if (request.getParameter("searchparam")==null || request.getParameter("searchparam").equals("")) {
		results=userloader.loadByPrimaryPortalRoleId(Id.generateId(PortalRole.DATA_TYPE, request.getParameter("instrole")));
	}
	else{*/
	//write the code again here
		SearchOperator op = SearchOperator.Contains;
		UserSearch.SearchKey key = UserSearch.SearchKey.UserName;
		if(request.getParameter("method").equals("2")){
			op = SearchOperator.StartsWith;
		}
		else if(request.getParameter("method").equals("3")){
			op = SearchOperator.Equals;
		}
		if(request.getParameter("attribute").equals("2")){
			key = UserSearch.SearchKey.GivenName;
		}
		else if(request.getParameter("attribute").equals("3")){
			key = UserSearch.SearchKey.FamilyName;
		}
		else if(request.getParameter("attribute").equals("4")){
			key = UserSearch.SearchKey.Email;
		}
		UserSearch s = UserSearch.getNameSearch(key, op, sparam);
		s.setUsePaging(false);
		List temp = userloader.loadByUserSearch(s);
		if(temp!=null){
			BbList secondaryRoles = new BbList();
			iter = temp.iterator();
			while(iter.hasNext()){
				User current = (User)iter.next();
				PortalRole  prole = loader.loadPrimaryRoleByUserId(current.getId());
				if(prole.getId().toExternalString().equals(request.getParameter("instrole"))){
					results.add(current);
				}
				else{
					secondaryRoles = loader.loadSecondaryRolesByUserId(current.getId());
					Iterator itr = secondaryRoles.iterator();
					while(itr.hasNext()){
						PortalRole srole = (PortalRole)itr.next();
						if(srole.getId().toExternalString().equals(request.getParameter("instrole"))){
							results.add(current);
							break;
						}
					}
				}
			}
		}
	//}
	// sort by last name, first name
	comparator = new GenericFieldComparator(BaseComparator.ASCENDING,"getFamilyName",User.class);
    comparator.appendSecondaryComparator(new GenericFieldComparator(BaseComparator.ASCENDING,"getGivenName",User.class));
    Collections.sort(results,comparator);
%>
<%=results.size()%> users found.<br>
<bbUI:list collection="<%=results%>" 
				collectionLabel="Users" 
				objectId="user" 
				className="User"
				sortUrl=""
				resultsPerPage="-1">

		<bbUI:listElement
                width=""
                label="Last Name"
                href=""><%=user.getFamilyName()%></bbUI:listElement>
	    <bbUI:listElement
                width=""
                label="First Name"
                href=""><%=user.getGivenName()%></bbUI:listElement>
		<bbUI:listElement
                width=""
                label="Username"
                href=""><%=user.getUserName()%></bbUI:listElement>
		<bbUI:listElement
                width=""
                label="Email"
                href=""><%=user.getEmailAddress()%></bbUI:listElement>
		<bbUI:listElement
                width=""
                label="Primary Role"
                href=""><%=(loader.loadPrimaryRoleByUserId(user.getId())).getRoleName()%></bbUI:listElement>
		<bbUI:listElement
                width=""
                label="Secondary Roles"
                href=""><% BbList secroles = loader.loadSecondaryRolesByUserId(user.getId());
				Iterator sitr = secroles.iterator();
				while(sitr.hasNext()){
					PortalRole curr = (PortalRole)sitr.next();
					out.print(curr.getRoleName()+", ");
				}
				%></bbUI:listElement>
		<bbUI:listElement
                width=""
                label=""
                href=""><a class="inlineAction" href="/webapps/blackboard/execute/modUser?user_id=<%=user.getId().toExternalString()%>">Modify </a></bbUI:listElement>
</bbUI:list>
<%
}
%>
</bbUI:docTemplate>
 </bbData:context>