package com.pethers.pehcs.ant;

import com.pethers.pehcs.messengers.LoginResult;
import com.pethers.pehcs.services.AuthenticationService;
import com.pethers.pehcs.services.AuthenticationServiceImpl;
import java.io.IOException;
import java.net.URL;
import java.util.ResourceBundle;
import java.util.logging.Level;
import java.util.logging.Logger;
import javafx.concurrent.Service;
import javafx.event.ActionEvent;
import javafx.event.Event;
import javafx.event.EventHandler;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.fxml.Initializable;
import javafx.geometry.Rectangle2D;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.control.Button;
import javafx.scene.control.Label;
import javafx.scene.control.ProgressIndicator;
import javafx.scene.control.TextField;
import javafx.scene.paint.Color;
import javafx.stage.Modality;
import javafx.stage.Screen;
import javafx.stage.Stage;

/**
 * FXML Controller class
 *
 * @author user
 */
public class LoginController implements Initializable {

    final static Integer OK_STATUS = 200;
    static LoginResult result;
    AuthenticationService authService;
    
    @FXML private TextField usernameTxt;
    @FXML private TextField passwordTxt;
    @FXML private Label statusLbl;
    @FXML private Button loginBtn;
    @FXML private ProgressIndicator loginProgressIndicator;
    /**
     * Initializes the controller class.
     */
    @Override
    public void initialize(URL url, ResourceBundle rb) {
        authService = AuthenticationServiceImpl.getInstance();
    }  
    
    @FXML
    private void login(ActionEvent event){
        loginBtn.setDisable(true);
        usernameTxt.clear();
        passwordTxt.clear();
        statusLbl.setText("");
        
        final Service<LoginResult> service = new AuthenticationServiceImpl();
        
        loginProgressIndicator.visibleProperty().bind(service.runningProperty());
        
        service.setOnSucceeded(new EventHandler(){
            @Override
            public void handle(Event event) {
                if((result=service.getValue())!=null){
                    statusLbl.setText("Successful login. Redirecting...");                
                    showMainScene();
                }else{
                    loginBtn.setDisable(false);
                    statusLbl.setText("Incorrect usernanme or password. Try again.");
                    statusLbl.setTextFill(Color.web("#dd5044"));
                }
            }
        });
        
        service.setOnFailed(new EventHandler(){
            @Override
            public void handle(Event event) {
                statusLbl.setText(service.getException().getMessage());
                statusLbl.setTextFill(Color.web("#dd5044"));
                loginBtn.setDisable(false);
            }
        });
        
        service.restart();
        
    }
    
    private void showMainScene(){
        try {
            FXMLLoader loader = new FXMLLoader(getClass().getResource("main.fxml"));
            Parent root = loader.load();
            Stage stage = (Stage) loginBtn.getScene().getWindow();
            stage.setTitle("Visits - PEHCS Point of Sale");
            Rectangle2D primScreenBounds = Screen.getPrimary().getVisualBounds();
            stage.setX((primScreenBounds.getWidth() - stage.getWidth()) / 2);
            stage.setY((primScreenBounds.getHeight() - stage.getHeight()) / 2);
            
            stage.setScene(new Scene(root));
        } catch (IOException ex) {
            Logger.getLogger(LoginController.class.getName()).log(Level.SEVERE, null, ex);
        }

    }
}
