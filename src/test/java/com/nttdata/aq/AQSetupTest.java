package com.nttdata.aq;
import static org.junit.Assert.*;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Map;
import java.util.TreeMap;

import javax.annotation.Resource;





import org.apache.commons.lang.builder.ToStringBuilder;
import org.apache.commons.lang.builder.ToStringStyle;
import org.apache.commons.logging.LogFactory;
import org.apache.log4j.BasicConfigurator;
import org.apache.log4j.Level;
import org.apache.log4j.Logger;
import org.junit.BeforeClass;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.*;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.ImportResource;
import org.springframework.context.annotation.Scope;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.ResultSetExtractor;
import org.springframework.jdbc.core.RowCallbackHandler;
import org.springframework.stereotype.Component;
import org.springframework.test.annotation.Rollback;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit4.AbstractTransactionalJUnit4SpringContextTests;
import org.springframework.test.context.junit4.SpringJUnit4ClassRunner;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.*;


// org.springframework.test.context.junit4.SpringJUnit4ClassRunner


/**
 * Test of AdvacedQueue {@link VtAqWrapper} and related classes
 * @author jj
 *
 */
@RunWith(SpringJUnit4ClassRunner.class)
//@ComponentScan(basePackageClasses=AQCommander.class)
//@ComponentScan(basePackages="com.nttdata.aq")
@ContextConfiguration("test-spring-jms-aq.xml")
@Configuration
public class AQSetupTest extends AbstractTransactionalJUnit4SpringContextTests  {

	//public static final oracle.jdbc.OracleDriver dummyGuyToForceClassloader=null;
	
	
	@Autowired(required=false)
	private AQCommander aqCommander;
	

	@Test
	public void testSimpleWiring(){
		assertNotNull(aqCommander);
		try {
			Thread.sleep(2000);
		} catch (InterruptedException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

//		jdbcTemplateTester.query("select sysdate from dual",
//				new org.springframework.jdbc.core.RowMapper<Object>(){
//			public Object mapRow(ResultSet rs, int rowNum) throws SQLException{
//				System.err.println( rs.getObject(1));
//				return new Object();
//			}
//		});
	} 
	
	
}
