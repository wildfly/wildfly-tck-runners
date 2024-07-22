<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml" indent="yes"/>

    <!-- traverse the whole tree, so that all elements and attributes are eventually current node -->
    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="//*[local-name()='project']
                         //*[local-name()='profiles']">
        <xsl:copy>
            <xsl:apply-templates select="document('profile.xml')/*"/>
            <xsl:apply-templates select="document('global-excludes-profile.xml')/*"/>
            <xsl:apply-templates select="document('se21-excludes-profile.xml')/*"/>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
