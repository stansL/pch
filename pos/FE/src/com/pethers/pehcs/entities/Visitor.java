/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.pethers.pehcs.entities;

import java.sql.Blob;
import java.util.Calendar;
import java.util.Date;

/**
 *
 * @author user
 */
public class Visitor{
    
    private String firstName;
    private String lastName;
    private String gender;
    private Date dateOfBirth;
    private Blob fingerPrint;
    private Blob picture;
    private String insurerName;

    public Visitor() {
    }

    public Visitor(String firstName, String lastName, String gender, Date dateOfBirth, String insurerName) {
        this.firstName = firstName;
        this.lastName = lastName;
        this.gender = gender;
        this.dateOfBirth = dateOfBirth;
        this.insurerName = insurerName;
    }

    public String getInsurerName() {
        return insurerName;
    }

    public void setInsurerName(String insurerName) {
        this.insurerName = insurerName;
    }
    
    

    public Blob getPicture() {
        return picture;
    }

    public void setPicture(Blob picture) {
        this.picture = picture;
    }

    
    
    public String getFirstName() {
        return firstName;
    }

    public void setFirstName(String firstName) {
        this.firstName = firstName;
    }

    public String getLastName() {
        return lastName;
    }

    public void setLastName(String lastName) {
        this.lastName = lastName;
    }

    public String getGender() {
        return gender;
    }

    public void setGender(String gender) {
        this.gender = gender;
    }

    public Date getDateOfBirth() {
        return dateOfBirth;
    }

    public void setDateOfBirth(Date dateOfBirth) {
        this.dateOfBirth = dateOfBirth;
    }

    public Blob getFingerPrint() {
        return fingerPrint;
    }

    public void setFingerPrint(Blob fingerPrint) {
        this.fingerPrint = fingerPrint;
    }

    public String getFullName(){
        return firstName+" "+lastName;
    }
    
    @Override
    public String toString() {
        return "Visitor{" + "firstName=" + firstName + ", lastName=" + lastName + ", gender=" + gender + ", dateOfBirth=" + dateOfBirth + '}';
    }
    
    public String getFormattedDateOfBirth(){
        Calendar cal = Calendar.getInstance();
        cal.setTime(dateOfBirth);
        String date = cal.get(Calendar.DATE)+"/"+cal.get(Calendar.MONTH)+"/"+cal.get(Calendar.YEAR);
        int age = Calendar.getInstance().get(Calendar.YEAR) -(cal.get(Calendar.YEAR));
        return age+" ("+date+")";
    }
    
    
}
