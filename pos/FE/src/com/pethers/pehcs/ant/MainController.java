package com.pethers.pehcs.ant;

/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

import com.neurotec.biometrics.NBiometricStatus;
import com.neurotec.biometrics.NFinger;
import com.neurotec.biometrics.NSubject;
import com.neurotec.biometrics.NTemplateSize;
import com.neurotec.biometrics.client.NBiometricClient;
import com.neurotec.devices.NDeviceManager;
import com.neurotec.devices.NDeviceType;
import com.neurotec.devices.NFScanner;
import com.neurotec.licensing.NLicense;
import com.pethers.pehcs.entities.Visitor;
import com.pethers.pehcs.neurotec.utils.ImageConverter;
import com.pethers.pehcs.neurotec.utils.LibraryManager;
import com.pethers.pehcs.services.CardService;
import java.net.URL;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.List;
import java.util.ResourceBundle;
import javafx.event.ActionEvent;
import javafx.event.Event;
import javafx.event.EventHandler;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.fxml.Initializable;
import javafx.geometry.Pos;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.control.Alert;
import javafx.scene.control.Alert.AlertType;
import javafx.scene.control.Button;
import javafx.scene.control.Label;
import javafx.scene.control.ProgressBar;
import javafx.scene.control.Tab;
import javafx.scene.control.TabPane;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.layout.AnchorPane;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.ColumnConstraints;
import javafx.scene.layout.GridPane;
import javafx.scene.layout.HBox;
import javafx.scene.layout.Priority;
import javafx.scene.layout.RowConstraints;
import javafx.scene.layout.VBox;
import javafx.scene.text.Font;
import javafx.stage.Modality;
import javafx.stage.Stage;
import org.kordamp.ikonli.javafx.FontIcon;

/**
 *
 * @author user
 */
public class MainController implements Initializable {
    public static NBiometricClient biometricClient = null;


    @FXML private BorderPane borderPane;
    @FXML private TabPane visitPane;
    @FXML private Button resumeButton;
    @FXML private Button addButton;
    ImageView fingerPrint;
    CardService cardService;
    
   
    private void fingerPrintScannerSetup(){
        final String components = "Biometrics.FingerExtraction,Devices.FingerScanners";
        LibraryManager.initLibraryPath();        
        
        List<String> requiredLicenses = new ArrayList<String>();
        requiredLicenses.add("Biometrics.FingerExtraction");
        requiredLicenses.add("Devices.FingerScanners");
        List<String> optionalLicenses = new ArrayList<>();
        optionalLicenses.add("Images.WSQ");

        FingersTools.getInstance().getClient().setUseDeviceManager(true);
        deviceManager = FingersTools.getInstance().getClient().getDeviceManager();
        deviceManager.setDeviceTypes(EnumSet.of(NDeviceType.FINGER_SCANNER));
        deviceManager.initialize();
        try {
            if (!NLicense.obtainComponents("/local", 5000, components)) {
                Alert alert = new Alert(AlertType.WARNING);
                alert.setTitle("No Licence");
                alert.setContentText("Could not obtain a licence");
                alert.show();
                return;
            }

            biometricClient = new NBiometricClient();
           
            biometricClient.setUseDeviceManager(true);
            NDeviceManager deviceManager = biometricClient.getDeviceManager();
            deviceManager.setDeviceTypes(EnumSet.of(NDeviceType.FINGER_SCANNER));
            deviceManager.initialize();
            ListDialogController.devices = deviceManager.getDevices();
            if (ListDialogController.devices.size() > 1) {
                showDevicesDialog();
            } else {
                Alert alert = new Alert(AlertType.ERROR);
                alert.setTitle("No scanner");
                alert.setContentText("No scanner was found");
                alert.showAndWait();
            }
           
           
        } catch (Exception th) {
            throw new RuntimeException(th);
        }
    }
    
    protected void updateFingersTools() {
            FingersTools.getInstance().getClient().reset();
            FingersTools.getInstance().getClient().setUseDeviceManager(true);
            FingersTools.getInstance().getClient().setFingersReturnBinarizedImage(true);
    }

    public static NBiometricStatus capture(NSubject subject){
        if(biometricClient==null){
            Alert alert = new Alert(AlertType.ERROR);
            alert.setTitle("Inadequate Initialization");
            alert.setContentText("This application did not initialize properly. Please, ensure relevant licences and installed");
            alert.showAndWait();
        }
            
        NBiometricStatus status = biometricClient.capture(subject);
        biometricClient.setFingersTemplateSize(NTemplateSize.LARGE);
        status = biometricClient.createTemplate(subject);
        return status;


    }
    
    private void showDevicesDialog()throws Exception{
        final FXMLLoader loader = new FXMLLoader(getClass().getResource("listDialog.fxml"));
        final Parent root = loader.load();
        final Scene scene = new Scene(root, 250, 150);
        Stage stage = new Stage();
        stage.initModality(Modality.APPLICATION_MODAL);
       // stage.initStyle(StageStyle.UNDECORATED);
        //stage.initOwner(emailField.getScene().getWindow());
        stage.setScene(scene);
        stage.setOnCloseRequest(new EventHandler(){
            @Override
            public void handle(Event event) {
                biometricClient.setFingerScanner((NFScanner) ListDialogController.getSelectedDevice());
            }
        });
        stage.show();
    }
    
    @FXML
    private void addVisit(ActionEvent event) {  
        HBox progressBarHolder = new HBox();
        progressBarHolder.setMaxHeight(-1.0);
        progressBarHolder.setPrefWidth(-1.0);
        progressBarHolder.setSpacing(2.0);
        
        Label statusLabel = new Label("Reading card...");
        progressBarHolder.getChildren().add(statusLabel);
        ProgressBar cardReadingProgressBar = new ProgressBar();
        
        cardReadingProgressBar.setPrefWidth(143.0);
        cardReadingProgressBar.setProgress(-1.0);
        cardReadingProgressBar.visibleProperty().bind(cardService.runningProperty());
        progressBarHolder.getChildren().add(cardReadingProgressBar);
        
        Button cancelCardReadingButton = new Button();
        cancelCardReadingButton.setStyle("-fx-border-width:1px;-fx-padding:0px");
        FontIcon icon = new FontIcon("fa-close");
        icon.setIconSize(16);
        cancelCardReadingButton.setGraphic(icon);
        cancelCardReadingButton.setOnAction(new EventHandler(){
            @Override
            public void handle(Event event) {
                cardService.cancel();
                borderPane.setBottom(null);
                Alert alert = new Alert(AlertType.INFORMATION);
                alert.setTitle("Information");
                alert.setHeaderText(null);
                alert.setContentText("Task Cancelled!");
                
                alert.show();
            }
        });
        progressBarHolder.getChildren().add(cancelCardReadingButton);
        
        borderPane.setBottom(progressBarHolder);        
        
        
        cardService.setOnFailed(new EventHandler(){
            @Override
            public void handle(Event event) {
                Alert alert = new Alert(AlertType.ERROR);
                alert.setTitle("Error reading from card");
                alert.setHeaderText(null);
                alert.setContentText("Please insert card and try again");

                alert.showAndWait();
            }
        });
        
        cardService.setOnSucceeded(new EventHandler(){
            @Override
            public void handle(Event event) {
                Visitor visitor = cardService.getValue();
                Tab visitorsTab = new Tab(visitor.getFullName());
                
                AnchorPane anchorPane = new AnchorPane();      
                anchorPane.getChildren().add(createGridPane(visitor));                
                anchorPane.getChildren().add(createLeftImageHolder(visitor,visitorsTab));                
                anchorPane.getChildren().add(createRightImageHolder(visitor));    
                anchorPane.getChildren().add(getInsurerLabel("Insurer: "+visitor.getInsurerName()));
                //anchorPane.getChildren().add(getInsurerValueLabel(visitor.getInsurerName()));  
                
                visitorsTab.setContent(anchorPane);
                visitPane.getTabs().add(visitorsTab);
                visitPane.getSelectionModel().select(visitorsTab);
                borderPane.setBottom(null);
            }
        });
        cardService.restart();        
    }

    private GridPane createGridPane(Visitor visitor){
        GridPane gridPane = new GridPane();
        gridPane.setHgap(50);
        gridPane.setLayoutX(311);
        gridPane.setLayoutY(98);
        gridPane.setVgap(25);
        
        Label genderLabel = makeLabel(228,84,"Gender");
        gridPane.add(genderLabel, 0, 1);
        Label nameLabel = makeLabel(228,57,"Name");
        gridPane.add(nameLabel, 0, 0);
        Label ageLabel = makeLabel(228,108,"Age");
        gridPane.add(ageLabel, 0, 2);              
        Label nameValLabel = makeLabel(293,57,visitor.getFullName());
        gridPane.add(nameValLabel, 1, 0);
        Label genderValLabel = makeLabel(293,84,visitor.getGender());
        gridPane.add(genderValLabel, 1, 1);
        Label ageValLabel = makeLabel(293,111,visitor.getFormattedDateOfBirth());
        gridPane.add(ageValLabel, 1, 2);
        
        ColumnConstraints col1 = new ColumnConstraints();col1.setHgrow(Priority.ALWAYS);col1.setMinWidth(10);
        ColumnConstraints col2 = new ColumnConstraints();col2.setHgrow(Priority.ALWAYS);col2.setMinWidth(10);
        RowConstraints row1 = new RowConstraints();row1.setMaxHeight(17);row1.setMaxHeight(10);row1.setPrefHeight(17);row1.setVgrow(Priority.ALWAYS);
        RowConstraints row2 = new RowConstraints();row2.setMaxHeight(17);row2.setMaxHeight(10);row2.setPrefHeight(17);row2.setVgrow(Priority.ALWAYS);
        RowConstraints row3 = new RowConstraints();row3.setMaxHeight(17);row3.setMaxHeight(10);row3.setPrefHeight(17);row3.setVgrow(Priority.ALWAYS);
        gridPane.getColumnConstraints().add(col1);
        gridPane.getColumnConstraints().add(col2);
        gridPane.getRowConstraints().add(row1);
        gridPane.getRowConstraints().add(row2);
        gridPane.getRowConstraints().add(row3);
        return gridPane;
    } 
   
    
    private VBox createRightImageHolder(Visitor visitor){
        VBox rightImageHolder = new VBox();
        rightImageHolder.setAlignment(Pos.CENTER);
        rightImageHolder.setLayoutX(638);
        rightImageHolder.setLayoutY(57);
        rightImageHolder.setPrefHeight(200);
        rightImageHolder.setSpacing(10);
        rightImageHolder.getChildren().add(createFingerPrintView(visitor));
        rightImageHolder.getChildren().add(createCaptureButton()); 
        return rightImageHolder;
    }
    private Label makeLabel(double x,double y,String text){
        Label label = new Label(text);
        label.setLayoutX(x);
        label.setLayoutY(y);
        return label;
    }                    
    
     
    private Label getInsurerLabel(String text){
        Label label = makeLabel(94,14,text);
        label.setFont(new Font(32));
        return label;
    }
    private ImageView createPictureView(Visitor visitor){
        //Set the card stored fingerprint
        ImageView picture = new ImageView();                
        picture.setImage((Image) visitor.getPicture());
        //Set imageView properties
        picture.setFitHeight(150);
        picture.setFitWidth(150);
        picture.setLayoutX(16);
        picture.setLayoutY(57);
        picture.setPickOnBounds(true);
        picture.setPreserveRatio(true);
        return picture;
    }
    
    private ImageView createFingerPrintView(Visitor visitor){
        //Set the card-stored picture
        ImageView fingerPrint = new ImageView();                
        fingerPrint.setImage((Image) visitor.getFingerPrint());
        //Set imageView properties
        fingerPrint.setFitHeight(150);
        fingerPrint.setFitWidth(150);
        fingerPrint.setLayoutX(479);
        fingerPrint.setLayoutY(57);
        fingerPrint.setPickOnBounds(true);
        fingerPrint.setPreserveRatio(true);
        return fingerPrint;
    }
    @Override
    public void initialize(URL url, ResourceBundle rb) {
        System.out.println("Calling the initializer");
        cardService = new CardService();
        
        FontIcon icon = new FontIcon("fa-play-circle");
        icon.setIconSize(24);
        resumeButton.setGraphic(icon);
        
        FontIcon addIcon = new FontIcon("fa-plus-circle");
        addIcon.setIconSize(24);
        addButton.setGraphic(addIcon);
        
        fingerPrintScannerSetup();
    }

    public Button createCloseVisitButton(final Tab tab){
        Button button = new Button("Close Visit");
        FontIcon icon = new FontIcon("fa-close");
        icon.setIconSize(24);
        button.setGraphic(icon);
        button.setOnAction(new EventHandler(){
            @Override
            public void handle(Event event) {
                tab.getTabPane().getTabs().remove(tab);
            }
            
        });
        return button;
    }
    
    public Button createCaptureButton(){
        Button button = new Button("Capture");
        FontIcon icon = new FontIcon("fa-camera");
        icon.setIconSize(24);
        button.setGraphic(icon);
        button.setOnAction(new EventHandler(){
            @Override
            public void handle(Event event) {
                //set progress
                NSubject subject = null;
                NFinger finger = null;
                subject = new NSubject();
                finger = new NFinger();
                subject.getFingers().add(finger);
                System.out.println("Capturing....");
                NBiometricStatus status = capture(subject);

                if (status == NBiometricStatus.OK) {
                    System.out.println("Template extracted");
                    fingerPrint.setImage(ImageConverter.toFxImage(subject.getFingers().get(0).getImage().toImage()));
                    
                } else {
                    Alert alert = new Alert(AlertType.ERROR);
                    alert.setContentText("Extraction failed");
                    alert.show();
                }
            }
        });
        return button;
    }
    
    public VBox createLeftImageHolder(Visitor visitor, Tab visitorsTab){
        VBox leftImageHolder = new VBox();
        leftImageHolder.setAlignment(Pos.CENTER);
        leftImageHolder.setLayoutX(16);
        leftImageHolder.setLayoutY(57);
        leftImageHolder.setPrefHeight(200);
        leftImageHolder.setSpacing(10);
        leftImageHolder.getChildren().add(createPictureView(visitor));
        leftImageHolder.getChildren().add(createCloseVisitButton(visitorsTab)); 
        return leftImageHolder;
    }
    
}
