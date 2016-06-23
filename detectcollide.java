package com.example.detect;

import android.support.v7.app.ActionBarActivity;
import android.os.Bundle;
import android.os.Environment;
import android.view.Menu;
import android.view.MenuItem;

import android.app.Activity;
import android.app.AlertDialog.Builder;
import android.app.ProgressDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.drawable.AnimationDrawable;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.location.GpsSatellite;
import android.location.Location;
import android.location.LocationListener;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.Handler;
import android.provider.MediaStore;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.KeyEvent;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup.LayoutParams;
import android.view.inputmethod.InputMethodManager;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.Toast;

import org.apache.http.util.EncodingUtils;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.TimeZone;
import java.util.Timer;
import java.util.TimerTask;

public class MainActivity extends ActionBarActivity {
	 private SensorManager sensorManager;
	 private MySensorEventListener mySensorEventListener;
	 private float gyr_x, gyr_y, gyr_z, com_x, com_y, com_z, mag_x, mag_y, mag_z, lgt, prom, pres;
	 private double T1, V;
	 private int T2;
	 private double lon, lat;
	 private double[] acc = new double[3];
	 private double[][] acv; 
	 private double[] avg1 = new double[3];
	 private double[] avg2 = new double[3];
	 private double[] conv = new double[3];
	 private int state = 0;
	 private long starttime, oldtime, newtime;
	 private String[] config = new String[3];
	 private Context context;
	 private Intent intent;
	 @Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_main);
		init();
	}
	private void init() {
	   context = this;
	   String fileName =  "congfig.txt";
       String res="";
       
       starttime = System.currentTimeMillis();
       
       intent = new Intent(MediaStore.ACTION_VIDEO_CAPTURE);
       startActivityForResult(intent,1);
       
       
       try{            
           File file = new File(Environment.getExternalStorageDirectory(),"config.txt");             
           FileInputStream fis = new FileInputStream(file);             
           byte[] buffer = new byte[fis.available()];  
                     
           fis.read(buffer);            
     
           fis.close();  
             
           res = EncodingUtils.getString(buffer, "UTF-8");  
           config = res.split("\t");

           
           T1 = Double.parseDouble(config[0]);
           T2 = Integer.parseInt(config[1]);
           V = Double.parseDouble(config[2]);
           
             
      }catch(Exception ex){  
           Toast.makeText(MainActivity.this, "wrong！", 1000).show();  
           T1 = 2.5;
           
           
           T2 = 3;
           
           V = 30;
       }  
     
       acv = new double[T2][3];
     
        
        sensorManager = (SensorManager) getSystemService(SENSOR_SERVICE);


        mySensorEventListener = new MySensorEventListener();
        List<Sensor> sensors = sensorManager.getSensorList(Sensor.TYPE_ALL);
        for (Sensor sensor : sensors) {
            sensorManager.registerListener(mySensorEventListener, sensor, SensorManager.SENSOR_DELAY_GAME);
        }

      
    }
/*
 * 
 * 
 * 	
*/	
	@Override 
	protected void onActivityResult(int requestCode, int resultCode, Intent data) { 
	super.onActivityResult(requestCode, resultCode, data); 
	if (resultCode == Activity.RESULT_OK) { 
	String sdStatus = Environment.getExternalStorageState(); 
	if (!sdStatus.equals(Environment.MEDIA_MOUNTED)) { // 检测sd是否可用 
	Log.v("TestFile", 
	"SD card is not avaiable/writeable right now."); 
	return; 
	} 
	Bundle bundle = data.getExtras(); 
	Bitmap bitmap = (Bitmap) bundle.get("data");// 获取相机返回的数据，并转换为Bitmap图片格式 
	FileOutputStream b = null; 
	File file = new File(Environment.getExternalStorageDirectory() + "/myImage/"); 
	file.mkdirs();// 创建文件夹 
	String fileName = Environment.getExternalStorageDirectory() + "/myImage/111.jpg"; 
	try { 
	b = new FileOutputStream(fileName); 
	bitmap.compress(Bitmap.CompressFormat.JPEG, 100, b);// 把数据写入文件 
	} catch (FileNotFoundException e) { 
	e.printStackTrace(); 
	} finally { 
	try { 
	b.flush(); 
	b.close(); 
	} catch (IOException e) { 
	e.printStackTrace(); 
	} 
	} 
	// 将图片显示在ImageView里 
	} 
	} 
/*
 * 
 * 	
 */
	 private class MySensorEventListener implements SensorEventListener {

	        @SuppressWarnings("deprecation")
	        @Override
	        public void onSensorChanged(SensorEvent event) {
	            switch (event.sensor.getType()) {

	                case Sensor.TYPE_ACCELEROMETER:

	                    acc[0] = event.values[0];
	                    acc[1] = event.values[1];
	                    acc[2] = event.values[2];
	                    if(Math.sqrt(acc[0] * acc[0] + acc[1] * acc[1]) > V)
	                    	Toast.makeText(context, "collide1", Toast.LENGTH_SHORT).show();
	                    else{
	                    	state = detect(acc, T1, T2, V);
	                    	if(state == 1)
		                    {	
	                    		newtime = System.currentTimeMillis();
	                    		if((newtime - starttime) > 1000 && (newtime - oldtime) > 2000)
	                    		{
		                        	Toast.makeText(context, "collide2", Toast.LENGTH_SHORT).show();
		                        	Log.i("old", String.valueOf(oldtime));
	                    			Log.i("new", String.valueOf(newtime));
	                    			oldtime = System.currentTimeMillis();
	                    			
	                    			}
	                    		
	                    				}
	                    }
	                    
	                    break;
	               
	            }
	        }
	        @Override
	        public void onAccuracyChanged(Sensor sensor, int accuracy) {//准确度改变时调用

	        }}
	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		// Inflate the menu; this adds items to the action bar if it is present.
		getMenuInflater().inflate(R.menu.main, menu);
		return true;
	}
	 private int detect(double acc[], double T, double T2, double V){
	        for(int i = 0; i < acv.length - 1 ; i ++)
	        	
	        {	for(int j = 0; j < 3; j++)
	        	acv[i][j] = acv[i+1][j];
	        	
	        }
	        for(int j = 0; j < 3; j++)
	        	
	        	acv[acv.length - 1][j] = acc[j];
	        
	        avg1 = getmean(acv, 0, acv.length - 1);
	       //Log.i("ACTIVITY_TAG", String.valueOf(avg1[2]));
	        //Log.i("ACTIVITY_TAG1", String.valueOf(acc[2]));
	        //avg1 = getmean(acv, 0, 2);
	        if((Math.abs((acc[0]- avg1[0])) > T) || (Math.abs(acc[1] - avg1[1]) > T) || (Math.abs(acc[2]- avg1[2]) > T)){
	         
	           return 1;

	        }
	        return 0;
	    }
	    private double max(double[] a){
	        double min = 10000;
	        for (int i = 0; i < a.length; i++ ){
	            if(min > a[i])
	                min = a[i];
	        }
	        return min;
	    }
	    private double[] getmean(double[][] acvf, int begin, int end){
	        double[] acvsum = new double[3];
	        for(int i = begin; i < end; i++){
	            acvsum[0] += acvf[i][0];
	            acvsum[1] += acvf[i][1];
	            acvsum[2] += acvf[i][2];
	        }
	        acvsum[0] /= (end - begin);
            acvsum[1] /= (end - begin);
            acvsum[2] /= (end - begin);
	        return acvsum;
	    }
	    
	    private double[] getvar(double[][] acv, double[] mean, int begin, int end){
	        double[] acvsum = new double[3];
	        for(int i = begin; i < end; i++){
	            acvsum[0] += (acv[i][0] - mean[0]) * (acv[i][0] - mean[0]);
	            acvsum[1] += (acv[i][1] - mean[1]) * (acv[i][1] - mean[1]);
	            acvsum[2] += (acv[i][2] - mean[2]) * (acv[i][2] - mean[2]);
	            if(i == end - 1){
	                acvsum[0] /= begin - end;
	                acvsum[1] /= begin - end;
	                acvsum[2] /= begin - end;
	            }
	        }
	        return acvsum;
	    }
	
	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		// Handle action bar item clicks here. The action bar will
		// automatically handle clicks on the Home/Up button, so long
		// as you specify a parent activity in AndroidManifest.xml.
		int id = item.getItemId();
		if (id == R.id.action_settings) {
			return true;
		}
		return super.onOptionsItemSelected(item);
	}

@Override
protected void onDestroy() {
    super.onDestroy();

    sensorManager.unregisterListener(mySensorEventListener);



}}