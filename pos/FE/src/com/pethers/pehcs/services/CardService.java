/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.pethers.pehcs.services;

import com.pethers.pehcs.entities.Visitor;
import java.util.Date;
import javafx.concurrent.Service;
import javafx.concurrent.Task;

/**
 *
 * @author user
 */
public class CardService extends Service<Visitor>{

    
    @Override
    protected Task<Visitor> createTask() {
        return new Task<Visitor>(){
            @Override
            protected Visitor call() throws Exception {
                Thread.sleep(3000);
                Date date = new Date();
                date.setDate(1);
                date.setMonth(2);
                date.setYear(85);
                return new Visitor("Ambrose","Ariagiegbe","Male",date,"Zenith");
            }
            
        };
    }
    
}
