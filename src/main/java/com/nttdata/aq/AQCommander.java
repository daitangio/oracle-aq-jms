package com.nttdata.aq;

import org.springframework.stereotype.Component;

@Component
public class AQCommander {

	public void handleCommandMessage(Object msg){
		System.err.println("Got:"+msg);
	}
}
