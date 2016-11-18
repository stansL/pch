/* Smartcard/Biometrics Healthcare Utility
 * fotang, mtf@fotang.info
 * Tue Nov 15 10:21:49 WAT 2016
 *
 * To compile:
 * javac -d . -cp asememory.jar:. CardSession.java
 * */

package info.fotang;/*.hutil; healthcare utilities */
/*import info.fotang.BloodGroup;
import  info.fotang.FP;
import  info.fotang.MaritalStatus;*/
import info.fotang.QTS_CardException;
import asememory.*;
import java.util.Arrays;
import java.util.Calendar;

public class CardSession{
		 
	private static final String SIGNATURE="PEHCS"; //card identifier
	private static final byte SIGNATURE_LEN=(byte)SIGNATURE.length();
	private MemCard memCard = null;
	private long cardType;
	private static int cardSize=8*1024;
	private String reader=null;
	private boolean inEditMode=false;
	/* any unwritten modifications? */
	private boolean iPersonalDataIsDirty=false;
	private boolean mPersonalDataIsDirty=false;

	private static final byte[] VERSION={1,0,2};//software version
/*
Header block starts at offset 0.
	0-4: signature
	5: major version number
	6: minor version number
	7: micro version number
	8: 
		bit 1: card status. 0=>active, good; 1=> no service
		bit 2-8: reserved
	9-15: reserved
Payload starts immediately after header
	16-  : personal data block 0
	     : personal data block 1
		 : photo block
		 : fingerprint block
		 : dispensations

*/
	private static final int HEADER_LEN=16; //leave 16 bytes at start of card, for preamble
	private static final int STATUS_OFFS=7; // offset of card status byte

	public static final long MODE_CHECKSUMS=1<<0;//verify checksums
	public static final long MODE_SIGNATURE=1<<1;//verify card signature
	public static final long MODE_VERSION=1<<2;//verify
	public static final long MODE_STRICT = MODE_VERSION|MODE_CHECKSUMS | MODE_SIGNATURE;
	public static final long PERM_READ=1<<5;
	public static final long PERM_WRITE=1<<6;
	public static final long PERM_READWRITE=PERM_READ|PERM_WRITE;
	public static final long PERM_READONLY=PERM_READ;
	private long mode;
//	private long permissions= PERM_READONLY;
	private static final long defaultMode= MODE_STRICT|PERM_READONLY;
	private static final int defaultTimeOut=10; //10 secs to insert card

//	private final byte VERSION_LEN=3;// 1 byte each for major,minor,milli version
//	private final byte VERSION_OFFS=SIGNATURE_LEN;


	public static final byte MAX_INSURER=16;
	public static final byte MAX_PLAN=16; // package/plan name
	public static final byte MAX_ID=12;
	public static final byte MAX_SURNAME=24;
	public static final byte MAX_MIDDLENAME=20;
	public static final byte MAX_LASTNAME=20;
	public static final byte MAX_TITLE=10;
	public static final byte MAX_ADDRESS=32;
	public static final byte MAX_CITY=16;
	public static final byte MAX_AUL2=16;
	public static final byte MAX_AUL1=4; /* region, state, ... */
	public static final byte MAX_COUNTRY=2; /* ISO country code */
	public static final int MAX_HEALTH_COMMENTS=128;
	public static final int MAX_PHOTO_SIZE=5120; //5KB


	private byte[] cardHeader=new byte[HEADER_LEN];


	/* DATA ON THE CARD */

	private int intDataVersion; // card data version as integer
	private final int PERSONAL_DATA_OFFS=HEADER_LEN;//personal data begins here
	/* immutable */
	private byte[] persDataChksum=new byte[2];
/*
 * ======== Data that is unlikely to change =======
 	private String insurer;
	private String surname;
	private String middleName;
	private String lastName;
	*/
	private static final int XTRA_LEN=4;
	/*
	 * next 4bytes:
	private java.util.Date DatedateOfBirth;//20bits
	private boolean gender; // gender; 1bit
	private byte bloodGroup;// 5 bits

	private String ID; //beneficiary ID
*/
	public static boolean FEMALE=true;
	public static boolean MALE=!FEMALE;
	/* length of above data, incl. checksum */
	private static final int IMMUTABLE_LEN=2+MAX_SURNAME+MAX_MIDDLENAME+MAX_LASTNAME+XTRA_LEN+MAX_ID+MAX_INSURER;
	private byte[] iPersonalData=new byte[IMMUTABLE_LEN];
	/* mutable */
	private byte[] mPersDataChksum=new byte[2];//low byte, high byte
/*
 	private String plan;
	private String title;
	private byte maritalStatus;//3bits
	reserved: 5 bits
	private String address;
	private String city;
	private String AUL2;
	private String AUL1;
	private String CC; //country code
	private byte numberChildren; //4bit
	private byte reserved;//4bit
	private String healthComments;//remarks etc
*/
	/* length of above data, incl. address checksum */
	private final int MUTABLE_LEN=MAX_TITLE+1+2+MAX_ADDRESS+MAX_CITY+MAX_AUL2+MAX_AUL1+MAX_COUNTRY+1+MAX_HEALTH_COMMENTS+MAX_PLAN;
	private byte[] mPersonalData=new byte[MUTABLE_LEN];
	private final int mPERSONAL_DATA_OFFS=PERSONAL_DATA_OFFS+IMMUTABLE_LEN;
	private final int PHOTO_OFFS=mPERSONAL_DATA_OFFS+MUTABLE_LEN;
	private int photo_offs; //offset of photograph
/*
	at photo_offs:
		0-1: size of photo
		2--: data
	*/
//Fingerprints address:
	private final int FP_OFFS=2+PHOTO_OFFS+MAX_PHOTO_SIZE;
	private int FP_offs; //address of fingerprint tamplates
	private byte numberOfFP;//number of fingerprints on card
	private final byte FP_MAGIC=0x9; //4bit magic number
	private final int FP_MAX_SIZE=900;
	private final int FP_MAX_COUNT=2;//max number of prints to keep. must fit into 4 bits.

// Prescription address:
	private final int DISPENSATION_OFFS = FP_OFFS + FP_MAX_COUNT* FP_MAX_SIZE;

/* 
	0: 4 high bits for number of fingerprints on card (0-FP_MAX_COUNT)
		4 bits reserved
for each FP, starting at FP_offs+1:
	0: 4bit (low) for finger (1-10),
	   4bit (high) magic number, 13 (0x0d)
	1-2: checksum
	3-4: size (LSB, MSB)
	5--: data
	*/


	/**
	 * Print error codes in string format
	 * @param e = ASEException object
	 */
	public static final void printError(ASEException e) {
		if(e!=null) {
		//	System.out.println("The Error Code="+e.errorCode);
		//	System.out.println("The Error Name="+e.errorName);
			System.err.println(e.getMessage());
		}
	}
	public static final void printError(QTS_CardException e) {
		if(e!=null) {
		//	System.out.println("The Error Code="+e.getErrorCode());
			System.err.println("Error: "+e.getMessage());
		}
	}
  /**
   * Get software version.
   * 
   * @return software version as byte[3].
   */
	public static byte[] getVersion(){
		return VERSION;
	}
	public void startEditing() throws QTS_CardException{
		if((mode&PERM_WRITE) == 0)
				throw new QTS_CardException("Session is read only.", QTS_CardException.EREAD_ONLY);
		inEditMode=true;
	}
	public void stopEditing(){
				inEditMode=false;
	}
	public long getMode(){
			return mode;
	}
	/**
	* Write changes to card.
	* 31.05.09 frobnicate data before write
	*/
	public void flush() throws ASEException{
			if(iPersonalDataIsDirty){
					short cs=shortChecksum(Arrays.copyOfRange(iPersonalData, 2, IMMUTABLE_LEN));
					iPersonalData[0]=LoByte(cs);
					iPersonalData[1]=HiByte(cs);
					frobnicate(iPersonalData);
					memCard.write(HEADER_LEN,iPersonalData,0,IMMUTABLE_LEN,MemCard.ASEMEM_WRITE_MODE);
					iPersonalDataIsDirty=false;
	//				System.err.println("i:"+makeFromLoHi(iPersonalData[0],iPersonalData[1]));

			}
			if(mPersonalDataIsDirty){
					short cs=shortChecksum(Arrays.copyOfRange(mPersonalData, 2, MUTABLE_LEN));
					mPersonalData[0]=LoByte(cs);
					mPersonalData[1]=HiByte(cs);
					frobnicate(mPersonalData);
					memCard.write(HEADER_LEN+IMMUTABLE_LEN,mPersonalData,0,MUTABLE_LEN,MemCard.ASEMEM_WRITE_MODE);
					mPersonalDataIsDirty=false;
	//				System.err.println("m:"+makeFromLoHi(mPersonalData[0],mPersonalData[1]));
			}
	}
	public void close() throws ASEException{
		memCard.disconnect(MemCard.ASEMEM_LEAVE_CARD);
	}
	private boolean checksumsOK(byte []data, int len){
		short cs=shortChecksum(Arrays.copyOfRange(data, 2, len));
		return(LoByte(cs) == data[0] && HiByte(cs) == data[1]);
	}

	private void  checkCardSignature() throws QTS_CardException{
		String sig=new String(cardHeader, 0, SIGNATURE_LEN);
	//	System.out.println("sig:"+sig+":"+SIGNATURE);
		if(!SIGNATURE.equals(sig))
			throw new QTS_CardException ("The signature on the card is not valid",QTS_CardException.EINVAD_SIGNATURE);
	}
	private void checkVersions()  throws QTS_CardException{
			// we shall maintain backward compatibility
		if(makeVersionInt(getDataVersion()) > makeVersionInt(getVersion()))
			throw new QTS_CardException ("The data/software version incompatibility", QTS_CardException.EVERSION_MISMATCH);

	}
// timeOut is in seconds
private static long connectToCardx(long timeOut, MemCard card, String readr) throws ASEException
	{
		if(readr==null){
			String readers[]=MemCard.listReaders();
			if(readers==null || readers.length==0)
				throw new NoReadersAvailableException();
				// use first reader
				readr=readers[0];
		}
		//Wait for card insertion 
		MemCard.waitForCardEvent(readr,MemCard.ASEMEM_CARD_IN, timeOut*1000);
		return card.connect(readr,MemCard.ASEMEM_SHARE_SHARED|MemCard.ASEMEM_XI2C);
	}
	private long connectToCard(long timeOut) throws ASEException
	{
		if(reader==null){
			String readers[]=MemCard.listReaders();
			if(readers==null || readers.length==0)
				throw new NoReadersAvailableException();
				// use first reader
				reader=readers[0];
		}
		//Wait for card insertion 
		MemCard.waitForCardEvent(reader,MemCard.ASEMEM_CARD_IN, timeOut*1000);
		return memCard.connect(reader,MemCard.ASEMEM_SHARE_SHARED|MemCard.ASEMEM_XI2C);
	}
	public static String[] getReaders() throws ASEException{
		String[] r={};
	/*	try{*/
			r=MemCard.listReaders();
		/*}catch(ASEException e){	e.printStackTrace();}
		finally{return r;}*/
		return r;
	}
	public String getReader(){
		return reader;
	}
	public String getCardType(){
			return cardType==MemCard.ASEMEM_XI2C? "XI2C":"I2C";
	}
  /**
   * Format version for display as string.
   * 
   * @return version formatted as String.
   */
	public static String formatVersion(byte[] v){
			return  (byteToInt(v[0]) +
			       "." +  byteToInt(v[1])+"." +  byteToInt(v[2]));
	}
	public byte[] getDataVersion(){
		byte[] dataVersion=new byte[3];
		dataVersion[0]=cardHeader[SIGNATURE_LEN];
		dataVersion[1]=cardHeader[SIGNATURE_LEN+1];
		dataVersion[2]=cardHeader[SIGNATURE_LEN+2];
		return dataVersion;
	}
	private static int makeVersionInt(byte[] v){
			// convert 2-byte version number to int
			return (byteToInt(v[0])*1000+byteToInt(v[1]));
	}
	private void writeDataVersion(byte []v) throws ASEException, QTS_CardException{
		if(!inEditMode)
			throw new QTS_CardException ("Not in editing mode",QTS_CardException.ENOT_EDIT_MODE);

		{
			memCard.write(SIGNATURE_LEN, v, 0,v.length,MemCard.ASEMEM_WRITE_MODE);
			memCard.read(0,cardHeader,0,HEADER_LEN,null,0);
		}
	}
	private void writeSignature() throws ASEException, QTS_CardException{
		if(!inEditMode)
			throw new QTS_CardException ("Not in editing mode",QTS_CardException.ENOT_EDIT_MODE);
		memCard.write(0, SIGNATURE.getBytes(), 0,SIGNATURE_LEN,MemCard.ASEMEM_WRITE_MODE);
	}

	public boolean cardIsGood(){
			/* service can be dispensed */
			byte buf=cardHeader[STATUS_OFFS];
			// to be completed
			return (buf&1) != 0;
	}
	/*
	public boolean invalidateCard() throws QTS_CardException{
			byte buf=cardHeader[STATUS_OFFS];
			return (buf&1) !== 0;
	}
*/
  /**
   * Format card.
   * 
   * @return size of card.
   */
	public static int formatCard(String theReader) throws ASEException,QTS_CardException{
		MemCard card=new MemCard();
		long type=connectToCardx(defaultTimeOut, card, theReader);
		if (type!=MemCard.ASEMEM_CARD_TYPE_XI2C) {
				card.disconnect(MemCard.ASEMEM_UNPOWER_CARD);
				throw new QTS_CardException("Not an extended I2C card");
		}
		int pos=0;
		final int SZ=512;
		int len=0;
		try{
			while(pos<cardSize){
				len=SZ; // b.length -- data length
				if(len+pos>cardSize)
					len=cardSize-pos;
				byte[] b=new byte[len];
				java.util.Arrays.fill(b,(byte)0);
				card.write(pos,
					b,
					0,
					b.length,
					MemCard.ASEMEM_WRITE_MODE);
				System.err.println(pos+"."+len);
				pos+=b.length;
			}
		}catch(InvalidParameterException e){}
		finally{return(pos);}
	}
		public void initialiseCard() throws ASEException, QTS_CardException{
			initialiseCard(false);
		}
	public void initialiseCard(boolean erase) throws ASEException, QTS_CardException{
		if(!inEditMode)
			throw new QTS_CardException ("Not in editing mode",QTS_CardException.ENOT_EDIT_MODE);
		if(erase) CardSession.formatCard(reader);
		writeSignature();
		writeDataVersion(VERSION);
	}

	private short shortChecksum(byte data[]){
// calculate data checksum
		java.util.zip.CRC32 crc=new java.util.zip.CRC32();

		crc.update(data);
		long c=crc.getValue();
		return (short) (c>>16 | (c&0xffff));

	}
	private short getIPersonalDataChecksum(){
		return (short)makeFromLoHi(iPersonalData[0], iPersonalData[1]);
	}
	/**
	 * replace part of an array @a with values from string @b.
	 * 
	 * */
	private void replace(byte[] a, byte[] b, int start, int maxlen){
		int i;
		for(i=0; i<maxlen && i<b.length;i++){
			a[start+i]=b[i];
		}
		for(;i<maxlen;i++)
			a[start+i]=0;
		//return a;
	}
	private void setData(byte[] dest, String val, int offs, int maxlen){
		byte[] b = new byte[maxlen];
		java.util.Arrays.fill(b,(byte)0);
		replace(dest, b, offs, maxlen);
		replace(dest, val.getBytes(), offs, maxlen);
	}

	public String getSurname(){
		return new String(iPersonalData, 2, MAX_SURNAME).trim();
	}
	public void setSurname(String s) throws QTS_CardException{
		if(!inEditMode)
			throw new QTS_CardException ("Not in editing mode",QTS_CardException.ENOT_EDIT_MODE);
		int offs=2;
		replace(iPersonalData,s.getBytes(), offs, MAX_SURNAME);
		iPersonalDataIsDirty=true;
	}
	public String getMiddleName(){
		return new String(iPersonalData, 2+MAX_SURNAME, MAX_MIDDLENAME).trim();
	}
	public void setMiddleName(String s) throws QTS_CardException{
		if(!inEditMode)
			throw new QTS_CardException ("Not in editing mode",QTS_CardException.ENOT_EDIT_MODE);
		replace(iPersonalData, s.getBytes(), 2+MAX_SURNAME,MAX_MIDDLENAME);
		iPersonalDataIsDirty=true;
	}
	public String getLastName(){
		return new String(iPersonalData,  2+MAX_SURNAME+ MAX_MIDDLENAME, MAX_LASTNAME).trim();
	}
	public void setLastName(String s) throws QTS_CardException{
		if(!inEditMode)
			throw new QTS_CardException ("Not in editing mode",QTS_CardException.ENOT_EDIT_MODE);
		replace(iPersonalData, s.getBytes(),2+MAX_SURNAME+ MAX_MIDDLENAME, MAX_LASTNAME);

		iPersonalDataIsDirty=true;
	}
	/*
	 * |   Y   | M | D | g | bg |
	 *     11    4   5   1   5
	 *
	 * */
	public java.util.Date getDateOfBirth(){
		int offs=2+ MAX_SURNAME+ MAX_MIDDLENAME+ MAX_LASTNAME;
		byte []buf=new byte[3]; /* ==date, gender */

	/*	buf[0]=iPersonalData[offs];
		buf[1]=iPersonalData[offs+1];
		buf[2]=iPersonalData[offs+2];*/
		System.arraycopy(iPersonalData, offs, buf, 0, 3);
		int tmp = (byteToInt(buf[0])<<16) | (byteToInt(buf[1])<<8) | byteToInt(buf[2]);
		int year=tmp>>13;
		int month=(tmp>>9) & 0x0f;
		int day=(tmp>>4)&0x1f;
		java.util.Calendar cal=java.util.Calendar.getInstance();
		cal.set(year,month-1,day);
	//	System.out.println("OUT:"+year+"-"+month+"-"+day+";"+tmp);
		return cal.getTime();
	}
	public void setDateOfBirth(java.util.Date DoB) throws QTS_CardException{
		if(!inEditMode)
			throw new QTS_CardException ("Not in editing mode",QTS_CardException.ENOT_EDIT_MODE);
		int offs=2+ MAX_SURNAME+ MAX_MIDDLENAME+ MAX_LASTNAME;
		byte []buf=new byte[3];
		java.util.Calendar cal = java.util.Calendar.getInstance();
		cal.setTime(DoB);
		short year=(short)(cal.get(Calendar.YEAR)&2047);//lower 11 bits,max year is 2047
		byte month=(byte)(cal.get(Calendar.MONTH)+1);
		byte day=(byte)(cal.get(Calendar.DAY_OF_MONTH));
	//	System.out.println(" IN:"+year+"-"+month+"-"+day);

		buf[0]=(byte)(year>>3);
		buf[1]=(byte) (((year&7) <<5) | (month<<1) | (day>>4));

		//clear higher 4 bits
		buf[2]&=0x0f;
		//reset them
		buf[2]|=(byte) (((day&15)<<4));
		replace(iPersonalData, buf, offs, 3);
		iPersonalDataIsDirty=true;
	}
	public boolean getGender(){
		int offs=2+ MAX_SURNAME+ MAX_MIDDLENAME+ MAX_LASTNAME;
		byte buf=iPersonalData[offs+2];

		return ((buf & 8) != 0)? FEMALE:MALE;
	}
	public void setGender(boolean sex) throws QTS_CardException{
		if(!inEditMode)
			throw new QTS_CardException ("Not in editing mode",QTS_CardException.ENOT_EDIT_MODE);
		int offs=2+ MAX_SURNAME+ MAX_MIDDLENAME+ MAX_LASTNAME;
		byte buf=iPersonalData[offs+2];
		if(sex==FEMALE)
			buf|= (1<<3); //set bit
		else
			buf&=0xf7; //unset bit
		iPersonalData[offs+2]=buf;
		iPersonalDataIsDirty=true;
	}
	public byte getBloodGroup(){
		int offs=2+ MAX_SURNAME+ MAX_MIDDLENAME+ MAX_LASTNAME;
		byte[] buf=new byte[2]; /* ==day, gender,  blood group */

		buf[0]=iPersonalData[offs+2];
		buf[1]=iPersonalData[offs+3];
		int tmp=(byteToInt(buf[0])&0x7)<<2 /* move 3 low bits to high */
		       | byteToInt(buf[1])>>6; /* move 2 high bits to low */
		return (byte)(tmp & 0x1f); // 5 bits
	}
	public void setBloodGroup(int g) throws QTS_CardException{
		if(!inEditMode)
			throw new QTS_CardException ("Not in editing mode",QTS_CardException.ENOT_EDIT_MODE);
		int offs=2+ MAX_SURNAME+ MAX_MIDDLENAME+ MAX_LASTNAME;
		byte buf[]=new byte[2];

		buf[0]=iPersonalData[offs+2];
		buf[1]=iPersonalData[offs+3];
		//use value in lower 5 bits
		g&=0x1f;
		//clear lower 3 bits
		buf[0]&=0xf8;
		//store upper 3 bits of value into them
		buf[0]|=(g>>2);
		//clear 2 higher bits
		buf[1]&= 0x3f;
		//store lower 2 bits of value into them
		buf[1]|=((g&3)<<6);
		iPersonalData[offs+2]=buf[0];
		iPersonalData[offs+3]=buf[1];

		iPersonalDataIsDirty=true;
	}
	public String getID(){
		int offs=2+ MAX_SURNAME+ MAX_MIDDLENAME+ MAX_LASTNAME+XTRA_LEN;
		return new String(iPersonalData, offs, MAX_ID).trim();
	}
	public void setID(String ID) throws QTS_CardException{
		if(!inEditMode)
			throw new QTS_CardException ("Not in editing mode",QTS_CardException.ENOT_EDIT_MODE);
		
		int offs=2+ MAX_SURNAME+ MAX_MIDDLENAME+ MAX_LASTNAME+XTRA_LEN;
		byte []b=ID.getBytes();
		replace(iPersonalData, b, offs, MAX_ID);

		iPersonalDataIsDirty=true;
	}
	public String getInsurer(){
		int offs=2+ MAX_SURNAME+ MAX_MIDDLENAME+ MAX_LASTNAME+XTRA_LEN+MAX_ID;
		return new String(iPersonalData, offs, MAX_INSURER).trim();
	}
	public void setInsurer(String s) throws QTS_CardException{
		if(!inEditMode)
			throw new QTS_CardException ("Not in editing mode",QTS_CardException.ENOT_EDIT_MODE);
		replace(iPersonalData, s.getBytes(), 2+ MAX_SURNAME+ MAX_MIDDLENAME+ MAX_LASTNAME+XTRA_LEN+MAX_ID,MAX_INSURER);
		iPersonalDataIsDirty=true;
	}

	/* data is likely to change often */
	private int getMPersonalDataChecksum(){
		return makeFromLoHi(mPersonalData[0], mPersonalData[1]);
	}

	public String getTitle(){
			return new String(mPersonalData, 2, MAX_TITLE).trim();
	}
	public void setTitle(String s) throws QTS_CardException{
		if(!inEditMode)
			throw new QTS_CardException ("Not in editing mode",QTS_CardException.ENOT_EDIT_MODE);
		int offs=2;
		replace(mPersonalData, s.getBytes(),offs, MAX_TITLE);
		mPersonalDataIsDirty=true;
	}
	public byte getMaritalStatus(){
			byte offs=2+MAX_TITLE;
			return (byte) ((mPersonalData[offs]>>5) & 0x7); //higher 3 bits of the byte
	}
	public void setMaritalStatus(byte s) throws QTS_CardException{
		if(!inEditMode)
			throw new QTS_CardException ("Not in editing mode",QTS_CardException.ENOT_EDIT_MODE);
		int offs=2+MAX_TITLE;
		byte buf=mPersonalData[offs];
		buf&=0x1f; //clear 3 high bits
		buf|= ((int)(s&0xff) <<5); //set them
		mPersonalData[offs]=buf;
		mPersonalDataIsDirty=true;
	}

	public String getAddress(){
		int offs= 2+MAX_TITLE+1;//skip title and marital status
		return new String(mPersonalData, offs, MAX_ADDRESS).trim();
	}
	public void setAddress(String s) throws QTS_CardException{
		if(!inEditMode)
			throw new QTS_CardException ("Not in editing mode",QTS_CardException.ENOT_EDIT_MODE);
		int offs=2+MAX_TITLE+1;
//		setData(mPersonalData,s, offs, MAX_ADDRESS);
		replace(mPersonalData, s.getBytes(), offs, MAX_ADDRESS);
		mPersonalDataIsDirty=true;
	}

	public String getCity(){
		int offs=2+ MAX_TITLE+1+MAX_ADDRESS;//skip title,marital status, address
		return new String(mPersonalData, offs, MAX_CITY).trim();
	}
	public void setCity(String s) throws QTS_CardException{
		if(!inEditMode)
			throw new QTS_CardException ("Not in editing mode",QTS_CardException.ENOT_EDIT_MODE);
		int offs=2+MAX_TITLE+1+MAX_ADDRESS;
//		setData(mPersonalData, s, offs, MAX_CITY);
		replace(mPersonalData, s.getBytes(), offs, MAX_CITY);
		mPersonalDataIsDirty=true;
	}

	public String getAUL2(){
		int offs=2+ MAX_TITLE+1+MAX_ADDRESS+MAX_CITY;//skip all above and city
		return new String(mPersonalData, offs, MAX_AUL2).trim();
	}

	public void setAUL2(String s) throws QTS_CardException{
		if(!inEditMode)
			throw new QTS_CardException ("Not in editing mode",QTS_CardException.ENOT_EDIT_MODE);
		int offs=2+MAX_TITLE+1+MAX_ADDRESS+MAX_CITY;
//		setData(mPersonalData, s, offs, MAX_AUL2);
		replace(mPersonalData, s.getBytes(), offs, MAX_AUL2);
		mPersonalDataIsDirty=true;
	}
	public String getAUL1(){
		int offs=2+ MAX_TITLE+1+MAX_ADDRESS+MAX_CITY+MAX_AUL2;//skip all above and AUL2
		return new String(mPersonalData, offs, MAX_AUL1).trim();
	}
	public void setAUL1(String s) throws QTS_CardException{
		if(!inEditMode)
			throw new QTS_CardException ("Not in editing mode",QTS_CardException.ENOT_EDIT_MODE);
		int offs=2+MAX_TITLE+1+MAX_ADDRESS+MAX_CITY+MAX_AUL2;
//		setData(mPersonalData, s, offs, MAX_AUL1);
		replace(mPersonalData, s.getBytes(), offs, MAX_AUL1);
		mPersonalDataIsDirty=true;
	}
	public String getCountryCode(){
		int offs=2+ MAX_TITLE+1+MAX_ADDRESS+MAX_CITY+MAX_AUL2+MAX_AUL1;
		return new String(mPersonalData, offs, MAX_COUNTRY).trim();
	}
	public void setCountryCode(String s) throws QTS_CardException{
		if(!inEditMode)
			throw new QTS_CardException ("Not in editing mode",QTS_CardException.ENOT_EDIT_MODE);
		int offs=2+MAX_TITLE+1+MAX_ADDRESS+MAX_CITY+MAX_AUL2+MAX_AUL1;
		replace(mPersonalData, s.getBytes(), offs, MAX_COUNTRY);
		mPersonalDataIsDirty=true;
	}


	public byte getNumberOfChildren(){
		int offs=2+ MAX_TITLE+1+MAX_ADDRESS+MAX_CITY+MAX_AUL2+MAX_AUL1+MAX_COUNTRY;
		byte tmp=mPersonalData[offs];
		return (byte) ((tmp>>4) & 0xf); //higher 4 bits
	}
	public void setNumberOfChildren(byte n){
		int offs=2+ MAX_TITLE+1+MAX_ADDRESS+MAX_CITY+MAX_AUL2+MAX_AUL1+MAX_COUNTRY;
		byte buf=mPersonalData[offs];
		n&=0x0f; //range: 0-15
		buf&=0x0f; //clear high 4 bits
		buf|= (n<<4);
		mPersonalData[offs]=buf;
		mPersonalDataIsDirty=true;
	}
	/*
	 * now reserved (4 bits)
	public byte getNumberOfPregnancies(){
		int offs=2+ MAX_TITLE+1+MAX_ADDRESS+MAX_CITY+MAX_AUL2+MAX_AUL1;
		byte tmp=mPersonalData[offs];
		return (byte) (tmp & 0xf); //lower 4 bits
	}
	
	public void setNumberOfPregnancies(byte n){
		int offs=2+ MAX_TITLE+1+MAX_ADDRESS+MAX_CITY+MAX_AUL2+MAX_AUL1;
		byte buf=mPersonalData[offs];
		n&=0x0f; //range: 0-15
		buf&=0xf0; //clear lower 4 bits
		buf|=n;
		mPersonalData[offs]=buf;
		mPersonalDataIsDirty=true;
	}
	*/
	public String getRemarks(){
		int offs=2+ MAX_TITLE+1+MAX_ADDRESS+MAX_CITY+MAX_AUL2+MAX_AUL1+1+MAX_COUNTRY;
	//	System.err.println("Reading remarks at "+ offs);
		return new String(mPersonalData, offs,  MAX_HEALTH_COMMENTS).trim();
	}
	public void setRemarks(String s) throws QTS_CardException{
		if(!inEditMode)
			throw new QTS_CardException ("Not in editing mode",QTS_CardException.ENOT_EDIT_MODE);
		int offs=2+MAX_TITLE+1+MAX_ADDRESS+MAX_CITY+MAX_AUL2+MAX_AUL1+1+MAX_COUNTRY;
//		setData(mPersonalData, s, offs, MAX_HEALTH_COMMENTS);
		replace(mPersonalData, s.getBytes(), offs, MAX_HEALTH_COMMENTS);
		mPersonalDataIsDirty=true;
	}

	public String getPlan(){
		int offs= 2+ MAX_TITLE+1+MAX_ADDRESS+MAX_CITY+MAX_AUL2+MAX_AUL1+1+MAX_COUNTRY +MAX_HEALTH_COMMENTS;
	//	System.err.println("Reading plan at "+ offs);
		return new String(mPersonalData, offs, MAX_PLAN).trim();
	}
	public void setPlan(String s) throws QTS_CardException{
		if(!inEditMode)
			throw new QTS_CardException ("Not in editing mode",QTS_CardException.ENOT_EDIT_MODE);
		int offs=2+ MAX_TITLE+1+MAX_ADDRESS+MAX_CITY+MAX_AUL2+MAX_AUL1+1+MAX_COUNTRY +MAX_HEALTH_COMMENTS;
//		setData(mPersonalData, s, offs, MAX_PLAN);
		replace(mPersonalData, s.getBytes(), offs, MAX_PLAN);
		mPersonalDataIsDirty=true;
	}

	public short getPhotoSize() throws ASEException{
		byte[] b=new byte[2];
		memCard.read(photo_offs, b, 0, 2, null, 0);
		return (short)makeFromLoHi((byte)(b[0]), (byte)(b[1]));
	}
	public byte[] getPhoto()  throws ASEException{
			int size=getPhotoSize();
			byte[] b=new byte[size];
			memCard.read(photo_offs+2, b, 0, size, null, 0);
			return b;
	}
	public void writePhoto(byte[] p)  throws ASEException, QTS_CardException{
			if(!inEditMode)
				throw new QTS_CardException ("Not in editing mode",QTS_CardException.ENOT_EDIT_MODE);
	        if(p.length>MAX_PHOTO_SIZE)
			    throw new QTS_CardException("Photo is too large", QTS_CardException.EPHOTO_TOO_LARGE);
			int size=p.length;

			/* The SDK crashes if we write too many bytes at once.
			 * Let's write in chunks of 512 btes.
			 *
			 * */
			final short X=512;
			int rest=size;
			
			while(rest>0){
				int x=rest>X? X: rest;
				int done=size-rest;
				byte[] buf=new byte[x];

				//use a copy. otherwise Java crashes.

				System.arraycopy(p, done, buf, 0, x);

				//System.err.println("-"+rest+"\tx="+x+"\t+"+done+"\t"+100*done/size+"%");
				memCard.write(PHOTO_OFFS+2+done, buf, 0,buf.length,MemCard.ASEMEM_WRITE_MODE);
				rest-=x;
			}
				//write size:
			byte []v={LoByte((short)size),HiByte((short)size)};
			memCard.write(PHOTO_OFFS, v , 0,2,MemCard.ASEMEM_WRITE_MODE);
	}
	public byte getNumberOfFP() throws ASEException{
			byte[] buf=new byte[1];
			memCard.read(FP_OFFS, buf, 0, 1, null, 0);
		//	System.err.println("get value at FP_OFFS:"+(int)(buf[0]&0xff));
			
			return (byte)(byteToInt(buf[0])>>4);
	}

	private int locateFP(byte finger) throws ASEException{
			/*
			search for a template. return address if found, else -1.
			*/
			int pos;
			byte nfp; //number of prints on card
			int ret=-1;

			nfp=getNumberOfFP();
			for(int i=0; i<(int)nfp;i++){
					byte[] buf=new byte[1];
					pos=(FP_OFFS+1)+FP_MAX_SIZE*i;
					try{
						memCard.read(pos, buf, 0, 1, null, 0);
						//System.err.println("locateFP:"+(buf[0]));
					}catch (InvalidParameterException e){break;}
					byte magic=(byte)(byteToInt(buf[0])>>4);
					//System.err.println("locateFP:value at "+pos+":"+(buf[0])+", magic pos:"+(int)magic);
					if((int)magic != FP_MAGIC) continue;
					//System.err.println("locateFP:magic "+(int)magic);
					if((buf[0]&0xf) == finger){
							//System.err.println("locateFP:Found "+(int)finger);
							ret=pos;
							break;
					}
			}
			return ret;
	}

	private int getFreeFPSlot() throws ASEException{
			//get first available location to store FP
			int pos=0;
			byte[] buf=new byte[1];
			int ret=-1;

			pos=(FP_OFFS+1);
			for(int i=1;pos<cardSize && i<=FP_MAX_COUNT;i++){
					try{
						memCard.read(pos, buf, 0, 1, null, 0);
					}catch (InvalidParameterException e){
							//end of card (??)
							break;
					}
					
					byte magic=(byte)(byteToInt(buf[0])>>4);
					//System.err.println("getFreeFPSlot:value at "+pos+":"+(buf[0]));
					if(magic == FP_MAGIC){
						pos=(FP_OFFS+1)+FP_MAX_SIZE*i;
						continue;
					}
					ret=pos;
					break;
			}
			return ret;
	}
	public byte[] getFPList() throws ASEException{
			//get a list of stored FPs
		//	int pos;
			int n=(int)getNumberOfFP();
			byte[] res=new byte[n]; 

			for(int i=0, j=0;j<n;i++){
					byte[] buf=new byte[1];
					int pos=(FP_OFFS+1)+FP_MAX_SIZE*i;
					try{
						memCard.read(pos, buf, 0, 1, null, 0);
					}catch (InvalidParameterException e){
							//end of card (??)
					//		System.err.println("EOC");
							break;
					}
					
					byte magic=(byte)(byteToInt(buf[0])>>4);
					if(magic == FP_MAGIC){
							res[j++]=(byte)(buf[0]&0xf);
					//		System.err.println(i+". Got "+(int)(buf[0]&0xf)+" at " + pos);
					}
			}
			return res;
			//return Arrays.copyOf(res, j);
	}


	public void writeFP(byte[] p, byte finger) throws ASEException, QTS_CardException{
			if(!inEditMode)
				throw new QTS_CardException ("Not in editing mode",QTS_CardException.ENOT_EDIT_MODE);
	        if(p.length>FP_MAX_SIZE)
			    throw new QTS_CardException("Fingerprint template is too large", QTS_CardException.EFP_TOO_LARGE);
			int size=p.length;

			final short X=256;
			int rest=size;
			int curPos;
			boolean found;
			byte n; //number of prints on card

			finger&=0xf; //4bits max
			curPos=locateFP(finger);
			n=getNumberOfFP();
			found=(curPos!=-1);
			if(!found)
			{
					if(n>FP_MAX_COUNT)
			    		throw new QTS_CardException("No slot for finger print template",
						QTS_CardException.ENO_SLOT_FOR_FP);
					//get free slot
					curPos=getFreeFPSlot();
					if(curPos==-1)
			    		throw new QTS_CardException("No space for finger print template",
					QTS_CardException.ENO_SPACE_FOR_FP);
			}
			/*System.err.println("#FP:"+n+(found?"":" not")+" found");
			System.err.println("CurPos="+curPos+
								"FP_OFFS="+FP_OFFS);*/
			while(rest>0){
				int x=rest>X? X: rest;
				int done=size-rest;
				byte[] buf=new byte[x];

				//use a copy. otherwise Java may crash.

				System.arraycopy(p, done, buf, 0, x);

				memCard.write(curPos+5+done, buf, 0,buf.length,MemCard.ASEMEM_WRITE_MODE);
				rest-=x;
			}
			byte[] buf=new byte[5];
			//record finger and magic number
			buf[0]=(byte)(finger | (FP_MAGIC<<4));
			//System.err.println("buf[0]:"+(buf[0]));
			//checksum:
			short cs=shortChecksum(p);
			buf[1]=LoByte(cs);
			buf[2]=HiByte(cs);
				//size:
			buf[3]=LoByte((short)size);
			buf[4]=HiByte((short)size);
			memCard.write(curPos, buf , 0,5,MemCard.ASEMEM_WRITE_MODE);
			if(!found){
			//update count of fingerprints and write magic number
					n++;
					buf[0]=(byte)((n<<4));
					memCard.write(FP_OFFS, buf , 0,1,MemCard.ASEMEM_WRITE_MODE);
			}

	}

	public void removeFP(byte finger, long key) throws ASEException, QTS_CardException{
			if(key!=8012005) return;
			int pos=locateFP(finger);
			if(pos!=-1){
					byte[] buf={0,0,0,0,0};//clear checksum and size
					//TODO zero all bytes
					memCard.write(pos, buf , 0,5,MemCard.ASEMEM_WRITE_MODE);
					int n=byteToInt(getNumberOfFP());
					/*
					if(n>FP_MAX_COUNT)
							error...
					*/
					n--;
					buf[0]=(byte)((n<<4));
					memCard.write(FP_OFFS, buf , 0,1,MemCard.ASEMEM_WRITE_MODE);
			}
	}
					
	public byte[] getFP(byte finger) throws ASEException, QTS_CardException{
			byte[] buf={};
			int pos=locateFP(finger);
			if(pos!=-1)
			{
					buf=new byte[5];
					memCard.read(pos, buf, 0, 5, null, 0);
					short size=makeFromLoHi(buf[3],buf[4]);
					short cs=makeFromLoHi(buf[1],buf[2]);

					buf=new byte[size];
					memCard.read(pos+5, buf, 0, size, null, 0);
					if(shortChecksum(buf) != cs)
							throw new QTS_CardException("Corrupt fingerprint feature",
					QTS_CardException.ECORRUPT_FP);

			}
			return buf;
	}

	private static void frobnicate(byte[] b){
		int i;
		for(i=0;i<b.length;i++)
				b[i]=(byte)(byteToInt(b[i]) ^ 42);
	}
	public static byte LoByte(short x){
		return (byte) (x&0xff);
	}
	public static byte HiByte(short x){
		return (byte)((x>>8));
	}
	public static short makeFromLoHi(byte lo, byte hi){
			return (short)( (int)(hi&0xff)<<8 | (int)(lo&0xff));
	}
	/**
	 *
	 * Convert a byte to an Int.
	 * Returns a number 0-255
	 */
	public static int byteToInt(byte b){
			return (int)(b&0xff);
	}
	public static String peek(int tout, String rdr) throws ASEException,TimeoutException,QTS_CardException{
		MemCard card=new MemCard();
		long type=connectToCardx(tout, card, rdr);
		if (type!=MemCard.ASEMEM_CARD_TYPE_XI2C) {
				card.disconnect(MemCard.ASEMEM_UNPOWER_CARD);
				throw new QTS_CardException("Not an extended I2C card");
		}
		byte[] id=new byte[MAX_ID];
		int offs=HEADER_LEN+2+ MAX_SURNAME+ MAX_MIDDLENAME+ MAX_LASTNAME+XTRA_LEN;
		card.read(offs,id,0,MAX_ID,null,0);
/*
	if(false)	{
// determine data version: to frobnicate or not to frobnicate
				byte[] cardHeaderx=new byte[HEADER_LEN];
				card.read(0,cardHeaderx,0,HEADER_LEN,null,0);
				byte[] dataVersion=new byte[2];
				dataVersion[0]=cardHeaderx[SIGNATURE_LEN];
				dataVersion[1]=cardHeaderx[SIGNATURE_LEN+1];
				if(makeVersionInt(dataVersion)>1000){ // after version 1.0
						frobnicate(id);
				}
		}else
*/
		frobnicate(id);
		card.disconnect(MemCard.ASEMEM_LEAVE_CARD);
		return new String(id).trim();
	}
	public CardSession(String aReader, long theMode, int timeOut) throws ASEException,QTS_CardException{
			reader=aReader;
			mode=theMode;
			memCard=new MemCard();
			cardType=connectToCard(timeOut);
			if (cardType!=MemCard.ASEMEM_CARD_TYPE_XI2C) {
			//	System.out.println("The inserted card is not (an extended) I2C card");
				memCard.disconnect(MemCard.ASEMEM_UNPOWER_CARD);
				throw new QTS_CardException("Not an extended I2C card");
			}
			memCard.read(0,cardHeader,0,HEADER_LEN,null,0);
			intDataVersion = makeVersionInt(getDataVersion());
			if((mode&MODE_SIGNATURE)!=0)
				checkCardSignature();
			//check version mismatch:
			if((mode&MODE_VERSION)!=0)
				checkVersions();
			
			
			//addr of fingerprint features
			FP_offs=FP_OFFS;/*makeFromLoHi(cardHeader[SIGNATURE_LEN+VERSION_LEN],
									cardHeader[SIGNATURE_LEN+VERSION_LEN+1]);*/
			// address of phtograph:
			
			photo_offs=PHOTO_OFFS;/*makeFromLoHi(cardHeader[SIGNATURE_LEN+VERSION_LEN+2],
									cardHeader[SIGNATURE_LEN+VERSION_LEN+3]);*/

			memCard.read(HEADER_LEN,iPersonalData,0,IMMUTABLE_LEN,null,0);
			memCard.read(HEADER_LEN+IMMUTABLE_LEN,mPersonalData,0,MUTABLE_LEN,null,0);
			// frobnicate
			//if(intDataVersion>1000){ // after version 1.0
					frobnicate(iPersonalData);
					frobnicate(mPersonalData);
			//}
			if(((mode&MODE_CHECKSUMS) != 0) && !(checksumsOK(iPersonalData, IMMUTABLE_LEN) && checksumsOK(mPersonalData, MUTABLE_LEN)))
					throw new QTS_CardException("Data on the card is corrupt", QTS_CardException.EBAD_CHECKSUM);

	}

	public CardSession(long theMode) throws ASEException,QTS_CardException{
			this(null, theMode,defaultTimeOut);
	}
	public CardSession(long theMode, int timeOut) throws ASEException,QTS_CardException{
			this(null, theMode, timeOut);
	}
	public CardSession(int timeOut) throws ASEException,QTS_CardException{
			this(null, defaultMode, timeOut);
	}
	public CardSession(String aReader, int timeOut) throws ASEException,QTS_CardException{
			this(aReader, defaultMode, timeOut);
	}

	public CardSession() throws ASEException,QTS_CardException{
			this(null, defaultMode, defaultTimeOut);
	}
}


