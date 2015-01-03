package com.nttdata.aq;

import org.springframework.stereotype.Component;

@Component
public class AQCommander {

    private int c=0;
	public void handleCommandMessage(Object msg){
		System.err.println("Got:"+msg);
	}
        public void handleHeartBeat(Object msg){
            System.err.println(this.toString()+" HeartBeat("+(++c)+"): "+msg);
            /*if((msg+"").equals("EXIT")){
                System.err.println(" HeartBeat: Exit requested...");
                System.exit(1000);
                }*/
        }
}
