/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.pethers.pehcs.messengers;

/**
 *
 * @author user
 */
public class LoginResult {
    
    String token = "";

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }


    public String toString(){
        return "Bearer "+token;
    }
    
}
