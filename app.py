from flask import Flask, render_template, url_for, request, send_from_directory, flash, redirect
import os
import subprocess
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.ticker import MaxNLocator

app = Flask(__name__)
app.secret_key = 'supersecretkey'
UPLOADS = 'uploads'
PROCESSED = 'processed'
IMAGES = 'static/images'
for folder in [UPLOADS, PROCESSED, IMAGES]:
    os.makedirs(folder, exist_ok=True)

def getSortedTime(key):
    key = str(key).strip()
    if len(key.split(" ")) == 5:
        Day, Month, Date, Time, Year = key.split(" ")
    elif len(key.split(" ")) == 4:
        Month, Date, Time, Year = key.split(" ")
    else:
        flash(f"Unexpected timestamp format: {key}")
        return "9999/99/99/000000"

    Month_map = {
        'Jan': 0, 'Feb': 1, 'Mar': 2, 'Apr': 3, 'May': 4, 'Jun': 5,
        'Jul': 6, 'Aug': 7, 'Sep': 8, 'Oct': 9, 'Nov': 10, 'Dec': 11
    }
    Hours, Mins, Sec = Time.split(":")
    secNo = int(Hours) * 3600 + int(Mins) * 60 + int(Sec)
    return f"{Year}/{Month_map[Month]:02}/{int(Date):02}/{secNo:06}"

def get_total_seconds(timestamp):
    Month_map = {
        'Jan': 0, 'Feb': 1, 'Mar': 2, 'Apr': 3, 'May': 4, 'Jun': 5,
        'Jul': 6, 'Aug': 7, 'Sep': 8, 'Oct': 9, 'Nov': 10, 'Dec': 11
    }
    parts = timestamp.strip().split()
    if len(parts) == 5:
        _, month, day, time, year = parts
    else:
        month, day, time, year = parts
    h, m, s = map(int, time.split(":"))
    return (int(year) * 365 * 86400 + Month_map[month] * 31 * 86400 +
            int(day) * 86400 + h * 3600 + m * 60 + s)

@app.route("/")
def landing():
    return render_template('landing.html')

@app.route("/uploads")
def upload():
    return render_template("upload.html")

@app.route('/uploads', methods=['POST'])
def upload_logs():
    file = request.files.get('logfile')
    if file and file.filename.endswith('.log'):
        filename = file.filename
        output_filename = filename.replace('.log', '.csv')
        filepath = os.path.join(UPLOADS, filename)
        file.save(filepath)
        result = subprocess.run(
            ['bash', 'bash_scripts/check.sh', filepath, output_filename],
            capture_output=True, text=True
        )
        if result.returncode != 0:
            flash(f"{result.stderr.strip()}")
            return redirect(url_for('landing'))
        return redirect(url_for('display_log', filename=output_filename))
    else:
        flash("You have to upload a .log file")
        return redirect(url_for('landing'))

@app.route('/display_logs/<filename>', methods=['GET', 'POST'])
def display_log(filename):
    filepath = os.path.join(PROCESSED, filename)
    filtered_filepath = os.path.join(PROCESSED, f"filtered_{filename}")
    log = []
    levels = set()
    columns = ['LineId', 'Time', 'Level', 'Content', 'EventId', 'EventTemplate']

    if request.method == 'POST':
        event_filter = request.form.get('eventFilter', '')
        level_filter = request.form.get('levelFilter', '')
        sort_by = request.form.get('sort_by', '')
        from_date = request.form.get('from', '')
        to_date = request.form.get('to', '')

        result = subprocess.run(
            ['bash', 'bash_scripts/filter.sh', filepath, filtered_filepath,
             event_filter, level_filter, from_date, to_date, sort_by],
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
    return send_from_directory(PROCESSED, filename, as_attachment=True)

@app.route('/download_filtered/<filename>')
def download_filtered_csv(filename):
    filtered_filename = f"filtered_{filename}"
    return send_from_directory(PROCESSED, filtered_filename, as_attachment=True)

@app.route('/download_plot/<filename>')
def download_plot(filename):
    return send_from_directory('static/images', filename, as_attachment=True)

@app.route('/plots/<filename>', methods=['GET', 'POST'])
def plots(filename):
    csvPath = os.path.join(PROCESSED, filename)
    data = np.genfromtxt(csvPath, dtype=str, delimiter=",", skip_header=1)
    if data.ndim == 1:
        data = np.array([data])
    timestamps = data[:, 1]
    levels = data[:, 2]
    events = data[:, 4]

    timeCount = {}
    for ts in timestamps:
        timeCount[ts] = timeCount.get(ts, 0) + 1

    sortedTime = sorted(timeCount.keys(), key=getSortedTime)
    from_date = request.form.get('from') or sortedTime[0]
    to_date = request.form.get('to') or sortedTime[-1]
    filtered_timestamps = [t for t in sortedTime if getSortedTime(from_date) <= getSortedTime(t) <= getSortedTime(to_date)]

    filtered_indices = np.isin(timestamps, filtered_timestamps)
    filtered_levels = levels[filtered_indices]
    filtered_events = events[filtered_indices]
    filtered_times = timestamps[filtered_indices]

    levelCount = {lvl: np.sum(filtered_levels == lvl) for lvl in np.unique(filtered_levels)}
    eventCount = {eid: np.sum(filtered_events == eid) for eid in np.unique(filtered_events)}

    sortedEvents = sorted(eventCount.keys(), key=lambda e: (int(e[1:]) if e[1:].isdigit() else e))

    x1 = np.array(filtered_times)
    y1 = np.array([timeCount[t] for t in x1])

    x2 = np.array(list(levelCount.keys()))
    y2 = np.array(list(levelCount.values()))

    x3 = np.array(sortedEvents)
    y3 = np.array([eventCount[e] for e in sortedEvents])

    plot_events_vs_time(x1, y1, filename)
    plot_level_distribution(x2, y2, filename)
    plot_event_code_distribution(x3, y3, filename)

    return render_template('plots.html', filename=filename)

def plot_events_vs_time(timestamps, freq, filename):
    seconds = np.array([get_total_seconds(t) for t in timestamps])
    rel_seconds = seconds - np.min(seconds)

    start_time = np.min(rel_seconds)
    end_time = np.max(rel_seconds)
    step = 1
    uniform_time = np.arange(start_time, end_time + 1, step)
    interpolated_freq = np.interp(uniform_time, rel_seconds, freq)

    fig, ax = plt.subplots(figsize=(12, 5))
    ax.plot(uniform_time, interpolated_freq, linewidth=1.2)

    ax.grid(True, which='both', linestyle='--', linewidth=0.5)
    ax.xaxis.set_major_locator(MaxNLocator(integer=True))

    n_ticks = min(10, len(uniform_time))
    tick_positions = np.linspace(start_time, end_time, n_ticks, dtype=int)
    tick_labels = [format_timestamp_from_seconds(t) for t in tick_positions]

    ax.set_xticks(tick_positions)
    ax.set_xticklabels(tick_labels, rotation=45, ha='right')

    ax.set_xlabel("Time", loc='right')
    ax.set_ylabel("Frequency", loc='top')
    ax.set_title("Event Frequency Over Time", loc='center')
    plt.tight_layout()
    plt.savefig(f'static/images/{filename}-event_distro.png')
    plt.close()

def format_timestamp_from_seconds(seconds):
    # Starting from fixed anchor date
    base_date = np.datetime64('2025-01-01')
    total_days = int(seconds // 86400)
    rem_secs = int(seconds % 86400)
    h = rem_secs // 3600
    rem_secs %= 3600
    m = rem_secs // 60
    s = rem_secs % 60
    date = base_date + np.timedelta64(total_days, 'D')
    return f"{str(date)} {h:02}:{m:02}:{s:02}"

def plot_level_distribution(labels, values, filename):
    plt.figure(figsize=(6, 6))
    plt.pie(values, labels=labels, autopct='%.2f%%', startangle=90)
    plt.tight_layout()
    plt.savefig(f'static/images/{filename}-level-count.png')
    plt.close()

def plot_event_code_distribution(labels, values, filename):
    plt.figure(figsize=(max(5, len(labels) * 0.6), 6))
    plt.bar(labels, values, width=0.5, color='skyblue')
    plt.gca().yaxis.set_major_locator(MaxNLocator(integer=True))
    plt.tight_layout()
    plt.savefig(f'static/images/{filename}-event-freq.png')
    plt.close()

if __name__ == "__main__":
    app.run(debug=True)
