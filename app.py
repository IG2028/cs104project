from flask import Flask,render_template,url_for,request,send_from_directory,flash,redirect
import os
import subprocess
import matplotlib.pyplot as plt
import numpy as np
def getSortedTime(key):                     #Function for key
    key=str(key)
    key=key.strip()
    # flash(f"printing {key.split(' ')}")
    if len(key.split(" "))==5:
        Day,Month,Date,Time,Year = key.split(" ")
    elif len(key.split(" "))==4:
        Month,Date,Time,Year = key.split(" ")
    else:
        flash(f"Unexpected timestamp format: {key}")
        return "9999/99/99/000000"

    Month_map={
        'Jan':0,'Feb':1,'Mar':2,'Apr':3,'May':4,'Jun':5,
        'Jul':6,'Aug':7,'Sep':8,'Oct':9,'Nov':10,'Dec':11
    }
    # Day_map={
    #     'Sun':0,'Mon':1,'Tue':2,'Wed':3,'Thu':4,'Fri':5,'Sat':6
    # }
    Hours,Mins,Sec=Time.split(":")
    Hours=int(Hours)
    Mins=int(Mins)
    Sec=int(Sec)
    secNo=int(Hours*3600+Mins*60+Sec)
    return f"{Year}/{Month_map[Month]:02}/{Date:02}/{secNo:06}"
app=Flask(__name__)
app.secret_key = 'supersecretkey'
UPLOADS='uploads'
PROCESSED='processed'
IMAGES='static/images'
for folder in [UPLOADS,PROCESSED,IMAGES]:
    os.makedirs(folder,exist_ok=True)
#app.config('UPLOADS')=UPLOADS
#app.config('PROCESSED')=PROCESSED
#app.config('IMAGES')=IMAGES
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
            ['bash','bash_scripts/check.sh',filepath,output_filename],
            capture_output=True,text=True
        )  
        if result.returncode !=0:
            flash(f"{result.stderr.strip()}")
            return redirect(url_for('landing'))
        return redirect(url_for('display_log',filename=output_filename))
    else:
        flash(f" You have to upload .log file")
        return redirect(url_for('landing'))
    
# @app.route('/display_logs')    
# def display_logs():
#     return render_template('display.html')

@app.route('/display_logs/<filename>', methods=['GET', 'POST'])
def display_log(filename):                  #change to add filters and sorts by also calling a bash script
    filepath=os.path.join(PROCESSED,filename)
    filtered_filepath=os.path.join(PROCESSED,f"filtered_{filename}")
    log=[]
    levels=set()
    columns=['LineId','Time','Level','Content','EventId','EventTemplate']
    # 
    # sort_by=request.form.get('sort_by')
    # result=subprocess.run(
    #     ['bash','bash_scripts/sorted_or_filtered.sh',filepath,from_date,to_date,sort_by],
    #     capture_output=True,text=True
    #     )
    # if result.returncode !=0:
    #     flash('Problem with sorting/filtering the file')
    #     return redirect(url_for('landing'))

    # Handle filtering/sorting
    if request.method == 'POST':
        event_filter = request.form.get('eventFilter', '')
        level_filter = request.form.get('levelFilter', '')
        sort_by = request.form.get('sort_by', '')
        from_date=request.form.get('from', '')
        to_date=request.form.get('to', '')

        result = subprocess.run(
            ['bash', 'bash_scripts/filter.sh', filepath, filtered_filepath, event_filter, level_filter, from_date, to_date, sort_by],
            capture_output=True, text=True
        )

        if result.returncode != 0:
            flash(f"Problem with sorting/filtering the file: {result.stderr.strip()}")
            return redirect(url_for('landing'))
        
        path_to_read = filtered_filepath
    else:
        path_to_read = filepath

    try:
        with open(path_to_read, 'r') as file:
            for idx, line in enumerate(file):
                if idx == 0:
                    continue
                rows = dict()
                row_list = line.strip().split(",")
                for i in range(len(columns)):
                    rows.update({columns[i]: row_list[i]})
                log.append(rows)
                levels.add(row_list[2])

        return render_template('display.html', log=log, columns=columns, filename=filename, levels=sorted(levels))
    except Exception as e:
        flash(f"Problem in reading csv file: {e}")
        return redirect(url_for('landing'))
    
@app.route('/download/<filename>')
def download_csv(filename):
    return send_from_directory(PROCESSED,filename,as_attachment=True) 

@app.route('/download_filtered/<filename>')
def download_filtered_csv(filename):
    filtered_filename = f"filtered_{filename}"
    return send_from_directory(PROCESSED, filtered_filename, as_attachment=True)

@app.route('/download_plot/<filename>')
def download_plot(filename):
    return send_from_directory('static/images', filename, as_attachment=True)

@app.route('/plots/<filename>',methods=['GET','POST'])
def plots(filename):
    csvPath=os.path.join(PROCESSED,filename)

    # data=np.genfromtxt(csvPath,dtype=str,delimiter=",",skip_header=1)

    # levels=data[:,2]
    # timestamps=data[:,1]
    # events=data[:,4]

    # time_plot_path= os.path.join('static/images',f"{filename}_event_time_plot.png")
    # level_plot_path= os.path.join('static/images',f"{filename}_level_distribution.png")
    # event_plot_path= os.path.join('static/images',f"{filename}_event_code_distribution.png")







    




























    Time=[]
#    time_format=['Month','Day','Date','Time','Year']            
    with open(csvPath,'r') as file:
        for idx, line in enumerate(file):
            if idx == 0:
                continue
            line=line.strip()
            fields=line.split(",")
            timestamp=fields[1]
            Time.append(timestamp)
    timeCount=dict()                        #for event distro 1
    for entry in Time:
        if entry not in timeCount.keys():
            timeCount[entry]=1
        else:
            timeCount[entry]+=1
    sortedTime=sorted(timeCount.keys(),key=getSortedTime)
    from_date=request.form.get('from') or sortedTime[0]
    to_date=request.form.get('to') or sortedTime[-1]
    filtered_timestamps=[time for time in sortedTime if getSortedTime(from_date)<=getSortedTime(time)<=getSortedTime(to_date)]
    levelCount=dict()
    eventCount=dict()
    with open(csvPath,'r') as file:
        for idx, line in enumerate(file):
            if idx == 0:
                continue
            fields=line.strip().split(",")
            if fields[1] in filtered_timestamps:
                level=fields[2]
                event=fields[4]
                if level not in levelCount.keys():
                    levelCount[level]=1
                else:
                    levelCount[level]+=1
                if event not in eventCount.keys():
                    eventCount[event]=1
                else:
                    eventCount[event]+=1
    
    sortedEvents=sorted(eventCount.keys())
    #x=np.array(filtered_timestamps)
    
    x1=np.array(filtered_timestamps)
    y1=np.array([timeCount[x] if x in timeCount else 0 for x in filtered_timestamps])
    x2=np.array([level for level in levelCount.keys()])
    y2=np.array([levelCount[level] for level in levelCount.keys()])
    x3=np.array([event for event in sortedEvents])
    y3=np.array([eventCount[event] for event in sortedEvents])
    plot_events_vs_time(x1,y1,filename)
    plot_level_distribution(x2,y2,filename)
    plot_event_code_distribution(x3,y3,filename)

    return render_template('plots.html',filename=filename)




def plot_events_vs_time(x1,y1,filename):
    plt.figure(figsize=(12,5))
    plt.plot(x1,y1,marker="o")
    plt.xticks(rotation=90)
    plt.grid(linewidth='0.5')
    plt.xlabel("timestamps",loc='right')
    plt.ylabel("Frequency",loc='top')
    plt.title('Event_freq_distro',loc='center')
    plt.tight_layout()
    plt.savefig(f'static/images/{filename}-event_distro.png')
    plt.close()

def plot_level_distribution(x2,y2,filename):
    plt.figure(figsize=(6,6))
    plt.pie(y2,labels=x2,autopct='%.2f%%',startangle=90)
    # plt.xlabel()
    # plt.ylabel()
    # plt.title()
    plt.tight_layout()
    plt.savefig(f'static/images/{filename}-level-count.png')
    plt.close()

def plot_event_code_distribution(x3,y3,filename):
    plt.figure(figsize=(max(5,len(x3)*0.6),6))
    plt.bar(x3,y3,width=0.5,color='skyblue')
    # plt.xlabel()
    # plt.ylabel()
    # plt.title()
    plt.tight_layout()
    plt.savefig(f'static/images/{filename}-event-freq.png')
    plt.close()

def get_secs_from_timestamp(timestamp):
    Month_map={
        'Jan':0,'Feb':1,'Mar':2,'Apr':3,'May':4,'Jun':5,
        'Jul':6,'Aug':7,'Sep':8,'Oct':9,'Nov':10,'Dec':11
    }
    timestamp=timestamp.strip()
    parts=timestamp.split(" ")

    parts=list(parts)
    if len(parts)==5:
            day, month, date, time, year = parts
    elif len(parts)==4:
            month, date, time, year = parts
        
    h,m,s = map(int,time.split(":"))
    totalSeconds = 3600*h + 60*m + s

    return totalSeconds
        


            
if __name__=="__main__":
    app.run(debug=True)

