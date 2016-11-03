/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.pethers.pehcs.services;

import com.pethers.pehcs.messengers.LoginResult;
import retrofit2.Call;
import retrofit2.http.GET;
import retrofit2.http.Query;

/**
 *
 * @author user
 */
public interface AuthenticationService {
    @GET("login")
    Call<LoginResult> login(@Query("username") String username,@Query("password") String password);
}
