/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.pethers.pehcs.ant;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Properties;

/**
 *
 * @author user
 */
public class PreferenceManager {
    private static PreferenceManager instance;
    private Properties prop;
    private File propFile = new File("preference.ini");

    
    private PreferenceManager() throws IOException{
        if(!propFile.exists()){
            propFile.createNewFile();
        }
        FileInputStream fis = new FileInputStream(propFile);
        prop = new Properties();
        prop.load(fis);        
    }
    
    public Properties getProps(){
        return prop;
    }
    
    public void setValueOfSelectedScanner(String value){
        prop.setProperty("selected_scanner", value);
    }
    
    public String getValueOfSelectedScanner(){
        return prop.getProperty("selected_scanner");
    }
    public void save() throws FileNotFoundException, IOException{
        getProps().store(new FileOutputStream(propFile),"no comment" );
    }
    
    public static PreferenceManager getInstance() throws IOException{
        if(instance==null)
            instance = new PreferenceManager();
        return instance;
    }
}
