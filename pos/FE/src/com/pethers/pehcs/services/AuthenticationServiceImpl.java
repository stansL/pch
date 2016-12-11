/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.pethers.pehcs.services;

import com.pethers.pehcs.messengers.LoginResult;
import javafx.concurrent.Service;
import javafx.concurrent.Task;
import retrofit2.GsonConverterFactory;
import retrofit2.Retrofit;

import java.util.logging.Level;
import java.util.logging.Logger;

/**
 *
 * @author user
 */
public class AuthenticationServiceImpl extends Service<LoginResult>{
    
    final static Integer OK_STATUS = 200;
    static LoginResult result;
    private String username;
    private String password;
    
    public static AuthenticationService getInstance(){
        Retrofit retrofit = new Retrofit.Builder()
                .baseUrl(Sites.BASE_URL).addConverterFactory(GsonConverterFactory.create())
                .build();
        AuthenticationService service = retrofit.create(AuthenticationService.class);
        return service;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }
    
    
    
    @Override
    protected Task<LoginResult> createTask() {
        return new Task<LoginResult>(){
            @Override
            protected LoginResult call() throws Exception {
                try {
                    //Response<LoginResult> response = getInstance().login(getUsername(), getPassword()).execute();
                    if(true /*|| response.code()==OK_STATUS*/){
                        //return response.body(); 
                        return new LoginResult();
                    }else{
                        return null;
                    }
                } catch (Exception ex) {
                    Logger.getLogger(AuthenticationServiceImpl.class.getName()).log(Level.SEVERE, null, ex);
                    return null;
                }
            }
            
        };
    }
}
