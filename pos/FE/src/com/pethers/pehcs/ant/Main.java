package com.pethers.pehcs.ant;

/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.stage.Stage;

/**
 *
 * @author user
 */
public class Main extends Application {    
        
    @Override
    public void start(Stage stage) throws Exception {
        System.loadLibrary("NLicensing");
        System.loadLibrary("NCore");
        System.loadLibrary("NBiometricClient");
        System.loadLibrary("NBiometrics");
        System.loadLibrary("NDevices");
        System.loadLibrary("NdmMedia");
        System.loadLibrary("NMedia");
        System.loadLibrary("NMediaProc");
        //System.load("FingersDetectSegmentsClassifier.ndf");
        
        setUserAgentStylesheet(STYLESHEET_MODENA);        
        Parent root = FXMLLoader.load(getClass().getResource("login.fxml"));
        
        Scene scene = new Scene(root);
        scene.getStylesheets().add("Styles.css");
        stage.setTitle("Login");
        stage.setScene(scene);
        stage.show();
        
    }

    
    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) {
        launch(args);
    }
    
}
