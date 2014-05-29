package com.nttdata.aq;

import javax.annotation.PostConstruct;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
//import org.springframework.batch.core.configuration.annotation.EnableBatchProcessing;
//import org.springframework.batch.core.configuration.annotation.JobBuilderFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springsource.loaded.agent.SpringLoadedPreProcessor;

/**
 * Main entry point
 * 
 * @author jj
 *
 */
@Controller
@EnableAutoConfiguration()
@ComponentScan
// @EnableBatchProcessing
public class AQDemoBoot {
	
	@RequestMapping("/about")
	@ResponseBody
	String about() {
		return "The AdvancedQueue+Gradle+SpringBoot+SpringLoaded_2014 Demo_is here.";
	}

	public static void main(String[] args) throws Exception {
		// ApplicationListener<ApplicationPreparedEvent> sayHello = new
		// ApplicationListener<ApplicationPreparedEvent>() {
		//
		// @Override
		// public void onApplicationEvent(ApplicationPreparedEvent event) {
		// System.err.println("\n\n\t DEMO READY\n\n");
		// }
		// };
		SpringApplicationBuilder ab = new SpringApplicationBuilder(
				AQDemoBoot.class);
		// ab.application().addListeners(sayHello);

		ab.run(args);

	}
}
