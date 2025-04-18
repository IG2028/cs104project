from flask import Flask,render_template,url_for,request,send_from_directory,flash,redirect
import os
import subprocess
import matplotlib.pyplot as plt
import numpy as np
app=Flask(__name__)
app.secret_key = 'supersecretkey'
UPLOADS='uploads'
PROCESSED='processed'
IMAGES='static/images'
for folder in [UPLOADS,PROCESSED,IMAGES]:
    os.makedirs(folder,exist_ok=True)
app.config('UPLOADS')=UPLOADS
app.config('PROCESSED')=PROCESSED
app.config('IMAGES')=IMAGES
@app.route("/")
def landing():
    return render_template('landing.html')
@app.route("/uploads")
def upload():
    return render_template("upload.html")
@app.route('/uploads',methods=['POST'])
def upload_logs():                          #change to get multiple files
    file=request.files.get('logfile')
    if file and file.filename.endswith('.log'):
        filename=file.filename
        output_filename=filename.replace('.log','.csv')
        filepath=os.path.join(UPLOADS,filename)
        file.save(filepath)
        result=subprocess.run(
            ['bash','bash_scripts/check.sh',filepath,UPLOADS/output_filename],
            capture_output=True,text=True
        )  
        if result.returncode !=0:
            flash("Invalid format of log file")
            return redirect(url_for('index'))
        return redirect(url_for('display_logs',filename=output_filename))
    else:
        flash("You have to upload .log file")
        return redirect(url_for('index'))
    
@app.route('/display_logs')    
def display_logs():
    return render_template('display.html')

@app.route('/display_logs/<filename>')
def display_log(filename):                  #change to add filters and sorts by also calling a bash script
    filepath=os.path.join(PROCESSED,filename)
    log=[]
    columns=['LineId','Time','Level','Content','EventId','EventTemplate']
    try:
        with open(filepath,'r') as file:             
            for line in file:
                rows=dict()
                line=line.strip()
                row_list=line.split(",")
                for i in range(len(columns)):
                    rows.update({columns[i]:row_list[i]})
                log.append(rows)
        return render_template('display.html',log=log,columns=columns,filename=filename)
    except Exception as e:
        flash(f"Problem in reading csv file: {e}")
        return redirect(url_for('index'))
    
@app.route('/download/<filename>')
def download_csv(filename):
    return send_from_directory(PROCESSED,filename,as_attachment=True) 
def getSortedTime(key):                     #Function for key
    key=str(key)
    Day,Month,Date,Time,Year = key.split(" ")
    Month_map={
        'Jan':0,'Feb':1,'Mar':2,'Apr':3,'May':4,'Jun':5,
        'Jul':6,'Aug':7,'Sep':8,'Oct':9,'Nov':10,'Dec':11
    }
    # Day_map={
    #     'Sun':0,'Mon':1,'Tue':2,'Wed':3,'Thu':4,'Fri':5,'Sat':6
    # }
    Hours,Min,Sec=Time.split(":")
    secNo=Hours*3600+Min*60+Sec
    return f"{Year}/{Month_map[Month]}/{Date}/{secNo}"


@app.route('/plots/<filename>',methods=['GET','POST'])
def plots(filename):
    csvPath=os.path.join(PROCESSED,filename)
    Time=[]
    time_format=['Month','Day','Date','Time','Year']            
    with open('csvPath','r') as file:
        for line in file:
            line=line.strip()
            fields=line.split(",")
            timestamp=fields[1]
            Time.append(timestamp)
            # #primer=timestamp.split(" ")
            # append={}
            # for i in range(len(time_format)):
            #     append.update({time_format[i]:primer[i]})
            # Time.append(append)
    timeCount=dict()
    for entry in Time:
        if entry not in timeCount.keys():
            timeCount[entry]=1
        else:
            timeCount[entry]+=1
    sortedTime=sorted(timeCount.keys(),key=getSortedTime)
    x=np.array(sortedTime)
    y=np.array(timeCount[key] for key in sortedTime)


            
                                                                    






    





if __name__=="__main__":
    app.run(debug=True)

