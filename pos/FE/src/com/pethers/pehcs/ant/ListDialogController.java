/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.pethers.pehcs.ant;

import com.neurotec.devices.NDevice;
import com.neurotec.devices.NDeviceManager;
import java.net.URL;
import java.util.ResourceBundle;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.event.ActionEvent;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.ListView;
import javafx.stage.Stage;

/**
 *
 * @author user
 */
public class ListDialogController implements Initializable{

    static NDeviceManager.DeviceCollection devices;
    @FXML private ListView listViewOfDevices;
    ObservableList<String> items =FXCollections.observableArrayList ();
    
    @Override
    public void initialize(URL location, ResourceBundle resources) {
        devices = MainController.getDevices();
        for(int i=0;i<devices.size();i++)
            items.add(devices.get(0).getDisplayName());
        listViewOfDevices.setItems(items);
    }
    
    public void handleDeviceSelection(ActionEvent event){
        MainController.selectedScannerIndex = listViewOfDevices.getSelectionModel().getSelectedIndex();
        ((Stage)listViewOfDevices.getScene().getWindow()).close();
    }
    
    
    
}
