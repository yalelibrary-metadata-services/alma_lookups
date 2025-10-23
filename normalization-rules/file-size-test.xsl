<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:marc="http://www.loc.gov/MARC21/slim">
  <xsl:mode on-no-match="shallow-copy"/>
  
  <!-- Variable to hold the external MARC records document; replace link to test different datasets -->
  <xsl:variable name="external-marc-data" as="document-node()?" select="document('https://raw.githubusercontent.com/yalelibrary-metadata-services/alma_rules_testing/refs/heads/main/datasets/470marc.xml')"/>
  
  <xsl:template match="datafield[@tag='245']">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      
      <!-- Get current 245 field for comparison -->
      <xsl:variable name="current-245" select="."/>
      
      <!-- Check for exact match in external MARC data -->
      <xsl:variable name="has-exact-match" as="xsd:boolean">
        <xsl:variable name="match-found" as="xsd:boolean*">
          <xsl:for-each select="$external-marc-data//datafield[@tag='245'] | $external-marc-data//marc:datafield[@tag='245']">
            <xsl:variable name="external-245" select="."/>
            
            <!-- Compare indicators -->
            <xsl:variable name="indicators-match" select="
              $current-245/@ind1 = $external-245/@ind1 and 
              $current-245/@ind2 = $external-245/@ind2"/>
            
            <!-- Get the correct subfield count for comparison -->
            <xsl:variable name="external-subfield-count" select="count($external-245/subfield) + count($external-245/marc:subfield)"/>
            
            <!-- Compare subfields (count, codes, and content) -->
            <xsl:variable name="subfields-match" as="xsd:boolean">
              <xsl:choose>
                <xsl:when test="count($current-245/subfield) != $external-subfield-count">
                  <xsl:sequence select="false()"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:variable name="subfield-comparisons" as="xsd:boolean*">
                    <xsl:for-each select="$current-245/subfield">
                      <xsl:variable name="pos" select="position()"/>
                      <xsl:variable name="current-subfield" select="."/>
                      <xsl:variable name="external-subfield" select="($external-245/subfield[$pos], $external-245/marc:subfield[$pos])[1]"/>
                      
                      <xsl:sequence select="
                        $current-subfield/@code = $external-subfield/@code and
                        string($current-subfield) = string($external-subfield)"/>
                    </xsl:for-each>
                  </xsl:variable>
                  <xsl:sequence select="every $comp in $subfield-comparisons satisfies $comp = true()"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            
            <!-- Return true if both indicators and subfields match -->
            <xsl:sequence select="$indicators-match and $subfields-match"/>
          </xsl:for-each>
        </xsl:variable>
        
        <!-- Return true if any match was found -->
        <xsl:sequence select="some $match in $match-found satisfies $match = true()"/>
      </xsl:variable>
      
      <!-- Copy all existing subfields -->
      <xsl:apply-templates select="subfield"/>
      
      <!-- Add $9 TRUE if exact match found -->
      <xsl:if test="$has-exact-match">
        <subfield code="9">
          <xsl:text>TRUE</xsl:text>
        </subfield>
      </xsl:if>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>
