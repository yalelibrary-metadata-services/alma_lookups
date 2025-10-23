<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <!--
    Currently tested only on eng book resources.
    Match 100 fields that:
      • have subfield 9 = 'no_linkage'
      • do not have a subfield d
      • $a contains YYYY- or YYYY-YYYY (either at end or embedded)
      • Ignore any number of $e if exist
      Additional conditions may be added in the future.
  -->
  
  <xsl:mode on-no-match="shallow-copy"/>
  <xsl:template match="
      datafield[@tag='100']
        [subfield[@code='9']='no_linkage']
        [not(subfield[@code='d'])]
        [subfield[@code='a'][matches(normalize-space(.), '\d{4}-(\d{4})?')]]
        [subfield[@code='a']/following-sibling::subfield[not(@code='e')][1][@code='9']]
    ">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <!-- $a string -->
      <xsl:variable name="a" select="normalize-space(string(subfield[@code='a'][1]))"/>
      
      <!-- Extract dates using regex that captures the date pattern -->
      <xsl:variable name="dates" select="replace($a, '^.*?(\d{4}-(\d{4})?).*$', '$1')"/>
      
      <!-- Remove dates and any surrounding punctuation/whitespace -->
      <xsl:variable name="name-with-extra" select="replace($a, '\s*,?\s*\d{4}-(\d{4})?\s*,?\s*', ' ')"/>
      <!-- Clean up extra spaces and trailing commas/periods -->
      <xsl:variable name="name" select="replace(normalize-space($name-with-extra), '[\.,]\s*$', '')"/>
      
      <!-- Is the immediate next subfield after $a a $9? -->
      <xsl:variable name="follows9"
        select="boolean(subfield[@code='a']/following-sibling::subfield[1][@code='9'])"/>
      
      <!-- Choose punctuation for $d:
           • full range + immediate $9 is period
           • full range + not immediate is comma
           • open range is hyphen '' -->
      <xsl:variable name="d-punct"
        select="
          if (matches($dates, '^\d{4}-\d{4}$')) then
            (if ($follows9) then '.' else ',')
          else
            ''
        "/>
      
      <!-- New $a: name only, with trailing comma + space -->
      <subfield code="a">
        <xsl:value-of select="concat($name, ', ')"/>
      </subfield>
      
      <!-- New $d: dates plus chosen punctuation (no trailing space) -->
      <subfield code="d">
        <xsl:value-of select="concat($dates, $d-punct)"/>
      </subfield>
      
      <!-- Copy remaining subfields in original order -->
      <xsl:apply-templates select="subfield[@code != 'a']"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
