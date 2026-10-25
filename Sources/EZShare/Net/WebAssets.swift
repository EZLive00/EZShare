import Foundation

/// 内嵌的网页资源（无外部依赖，离线可用）。
enum WebAssets {
    static let css = #"""
*,*::before,*::after{box-sizing:border-box}
:root{
  --bg:#f3f5fa; --bg2:#eef1f8; --panel:#ffffff; --panel-soft:#fbfcfe;
  --text:#161c26; --muted:#6c7789; --line:#e6eaf3; --line-soft:#eef1f7;
  --accent:#2f6bff; --accent-2:#12b5a5; --accent-soft:#ebf1ff;
  --hover:#f6f8fd; --shadow:0 1px 2px rgba(22,32,52,.06),0 8px 24px -12px rgba(22,32,52,.18);
  --radius:14px;
}
@media (prefers-color-scheme:dark){
  :root{
    --bg:#0e1218; --bg2:#11161e; --panel:#161c26; --panel-soft:#1a212c;
    --text:#e9eef7; --muted:#8b97aa; --line:#242c39; --line-soft:#1e2531;
    --accent:#5b8cff; --accent-2:#2bd1bf; --accent-soft:#1a2438;
    --hover:#1b222d; --shadow:0 1px 2px rgba(0,0,0,.4),0 12px 32px -16px rgba(0,0,0,.7);
  }
}
html,body{margin:0;padding:0}
body{
  font-family:-apple-system,BlinkMacSystemFont,"SF Pro SC","PingFang SC","Helvetica Neue",Arial,sans-serif;
  font-size:14px;line-height:1.45;color:var(--text);
  background:radial-gradient(1200px 600px at 12% -10%,var(--accent-soft),transparent 60%),var(--bg);
  min-height:100vh;-webkit-font-smoothing:antialiased;
}
a{color:inherit;text-decoration:none}
button{font-family:inherit;font-size:inherit;cursor:pointer;border:0;background:none;color:inherit}
input{font-family:inherit;font-size:inherit}
::selection{background:color-mix(in srgb,var(--accent) 26%,transparent)}

/* ---------- top bar ---------- */
.topbar{position:sticky;top:0;z-index:30;border-bottom:1px solid var(--line);background:var(--panel);background:color-mix(in srgb,var(--panel) 86%,transparent);-webkit-backdrop-filter:saturate(180%) blur(18px);backdrop-filter:saturate(180%) blur(18px)}
.topbar-inner{max-width:1120px;margin:0 auto;padding:13px 22px;display:flex;align-items:center;gap:12px}
.brand{display:flex;align-items:center;gap:10px;min-width:0}
.brand .mark{width:34px;height:34px;border-radius:10px;flex:none;display:grid;place-items:center;background:linear-gradient(140deg,#2f6bff,#12b5a5);box-shadow:0 6px 14px -6px rgba(47,107,255,.7)}
.brand .mark svg{width:19px;height:19px;stroke:#fff}
.brand .title{font-size:15px;font-weight:650;letter-spacing:.2px;white-space:nowrap}
.brand .sub{font-size:11.5px;color:var(--muted);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:36vw}
.spacer{flex:1}
.chip{display:inline-flex;align-items:center;gap:6px;height:28px;padding:0 10px;border-radius:999px;font-size:12px;font-weight:550;background:var(--accent-soft);color:var(--accent);white-space:nowrap}
.chip .dot{width:6px;height:6px;border-radius:50%;background:var(--accent-2);box-shadow:0 0 0 3px color-mix(in srgb,var(--accent-2) 22%,transparent)}

/* ---------- buttons ---------- */
.btn{display:inline-flex;align-items:center;gap:6px;height:32px;padding:0 12px;border-radius:9px;font-size:13px;font-weight:550;color:var(--text);background:var(--panel-soft);border:1px solid var(--line);transition:.16s ease;white-space:nowrap}
.btn:hover{background:var(--hover);border-color:color-mix(in srgb,var(--accent) 35%,var(--line))}
.btn:active{transform:translateY(.5px)}
.btn.primary{background:linear-gradient(135deg,#3b74ff,#2f6bff);color:#fff;border-color:transparent;box-shadow:0 6px 16px -8px rgba(47,107,255,.9)}
.btn.primary:hover{filter:brightness(1.06)}
.btn svg{width:15px;height:15px;stroke:currentColor;fill:none;stroke-width:1.8;stroke-linecap:round;stroke-linejoin:round}
.btn.ghost{background:transparent;border-color:transparent;color:var(--muted)}
.btn.ghost:hover{color:var(--text);background:var(--hover)}
.btn.danger{color:#e5484d;border-color:color-mix(in srgb,#e5484d 28%,var(--line))}
.btn.danger:hover{background:color-mix(in srgb,#e5484d 10%,transparent)}
.btn.icon{width:32px;padding:0;justify-content:center}

/* ---------- layout ---------- */
main{max-width:1120px;margin:0 auto;padding:18px 22px 64px}
.crumbs{display:flex;align-items:center;gap:6px;flex-wrap:wrap;font-size:13px;color:var(--muted);margin:2px 0 14px}
.crumbs a{padding:3px 7px;border-radius:7px;transition:.15s}
.crumbs a:hover{background:var(--hover);color:var(--text)}
.crumbs .sep{opacity:.45}
.crumbs .current{color:var(--text);font-weight:600}

.panel{background:var(--panel);border:1px solid var(--line);border-radius:var(--radius);box-shadow:var(--shadow);overflow:hidden}
.toolbar{display:flex;align-items:center;gap:10px;padding:12px 16px;border-bottom:1px solid var(--line-soft)}
.search{flex:1;display:flex;align-items:center;gap:8px;height:34px;padding:0 11px;border-radius:9px;background:var(--panel-soft);border:1px solid var(--line)}
.search:focus-within{border-color:color-mix(in srgb,var(--accent) 45%,var(--line));box-shadow:0 0 0 3px color-mix(in srgb,var(--accent) 12%,transparent)}
.search svg{width:15px;height:15px;stroke:var(--muted);fill:none;stroke-width:1.8}
.search input{flex:1;border:0;outline:0;background:transparent;color:var(--text);min-width:0}
.search input::placeholder{color:var(--muted)}
.count{font-size:12px;color:var(--muted);white-space:nowrap}

/* ---------- table ---------- */
table{width:100%;border-collapse:collapse}
thead th{font-size:11px;letter-spacing:.05em;text-transform:uppercase;color:var(--muted);font-weight:650;text-align:left;padding:9px 16px;border-bottom:1px solid var(--line-soft)}
tbody td{padding:9px 16px;border-bottom:1px solid var(--line-soft);vertical-align:middle}
tbody tr:last-child td{border-bottom:0}
tbody tr:hover td{background:var(--hover)}
td.name{width:auto}
td.size,td.time{color:var(--muted);font-size:12.5px;white-space:nowrap;font-variant-numeric:tabular-nums}
td.actions{text-align:right;white-space:nowrap;width:1%}
.rowlink{display:flex;align-items:center;gap:11px;min-width:0}
.icon{width:30px;height:30px;border-radius:9px;flex:none;display:grid;place-items:center}
.icon svg{width:17px;height:17px;fill:none;stroke:currentColor;stroke-width:1.7;stroke-linecap:round;stroke-linejoin:round}
.icon.folder{background:color-mix(in srgb,#2f6bff 12%,transparent);color:#2f6bff}
.icon.image{background:color-mix(in srgb,#8b5cf6 12%,transparent);color:#8b5cf6}
.icon.video{background:color-mix(in srgb,#ec4899 12%,transparent);color:#ec4899}
.icon.audio{background:color-mix(in srgb,#10b981 12%,transparent);color:#10b981}
.icon.archive{background:color-mix(in srgb,#f59e0b 14%,transparent);color:#d97706}
.icon.code{background:color-mix(in srgb,#14b8a6 12%,transparent);color:#0d9488}
.icon.doc{background:color-mix(in srgb,#3b82f6 10%,transparent);color:#2563eb}
.icon.file{background:color-mix(in srgb,#94a3b8 16%,transparent);color:#64748b}
@media (prefers-color-scheme:dark){
  .icon.folder{color:#7aa2ff}.icon.image{color:#b794ff}.icon.video{color:#f472b6}
  .icon.audio{color:#4ade80}.icon.archive{color:#fbbf24}.icon.code{color:#2dd4bf}
  .icon.doc{color:#93b4ff}.icon.file{color:#a3b0c2}
}
.fname{font-weight:520;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.fname:hover{color:var(--accent)}
.act{opacity:0;transition:.15s}
tr:hover .act{opacity:1}
@media (max-width:720px){
  td.time,th.time{display:none}
  .act{opacity:1}
  .brand .sub{display:none}
  main{padding:14px 12px 80px}
  .topbar-inner{padding:11px 14px}
}
.empty{padding:64px 20px;text-align:center;color:var(--muted)}
.empty svg{width:44px;height:44px;stroke:currentColor;fill:none;stroke-width:1.3;opacity:.5}
.empty h3{margin:12px 0 4px;font-size:15px;color:var(--text);font-weight:600}
.empty p{margin:0;font-size:13px}

/* ---------- footer ---------- */
footer{max-width:1120px;margin:0 auto;padding:0 22px 40px;color:var(--muted);font-size:12px;display:flex;gap:8px;align-items:center;justify-content:center}
footer .dot{width:4px;height:4px;border-radius:50%;background:currentColor;opacity:.4}

/* ---------- upload dock ---------- */
#dock{position:fixed;right:20px;bottom:20px;width:320px;display:none;flex-direction:column;gap:8px;z-index:60}
#dock.on{display:flex}
.up{background:var(--panel);border:1px solid var(--line);border-radius:12px;box-shadow:var(--shadow);padding:10px 12px;font-size:12.5px}
.up .t{display:flex;justify-content:space-between;gap:10px;margin-bottom:7px}
.up .t b{font-weight:600;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.up .t span{color:var(--muted);flex:none}
.bar{height:5px;border-radius:99px;background:var(--line);overflow:hidden}
.bar i{display:block;height:100%;width:0;border-radius:99px;background:linear-gradient(90deg,#2f6bff,#12b5a5);transition:width .2s ease}

/* ---------- drop overlay ---------- */
#drop{position:fixed;inset:0;z-index:80;display:none;place-items:center;background:color-mix(in srgb,var(--bg) 72%,transparent);-webkit-backdrop-filter:blur(6px);backdrop-filter:blur(6px)}
#drop.on{display:grid}
#drop .zone{width:min(520px,84vw);padding:52px 24px;border-radius:22px;border:2px dashed color-mix(in srgb,var(--accent) 55%,transparent);background:var(--panel);text-align:center;box-shadow:var(--shadow)}
#drop h2{margin:0 0 6px;font-size:18px}
#drop p{margin:0;color:var(--muted);font-size:13px}

/* ---------- modal ---------- */
#modal{position:fixed;inset:0;z-index:90;display:none;place-items:center;background:rgba(12,17,26,.38);-webkit-backdrop-filter:blur(3px);backdrop-filter:blur(3px)}
#modal.on{display:grid}
.dialog{width:min(400px,88vw);background:var(--panel);border:1px solid var(--line);border-radius:16px;box-shadow:0 24px 60px -20px rgba(0,0,0,.45);padding:20px}
.dialog h3{margin:0 0 6px;font-size:15px}
.dialog p{margin:0 0 14px;color:var(--muted);font-size:13px;word-break:break-all}
.dialog input{width:100%;height:36px;padding:0 12px;border-radius:9px;border:1px solid var(--line);background:var(--panel-soft);color:var(--text);outline:0}
.dialog input:focus{border-color:var(--accent);box-shadow:0 0 0 3px color-mix(in srgb,var(--accent) 12%,transparent)}
.dialog .foot{display:flex;justify-content:flex-end;gap:8px;margin-top:16px}

/* ---------- toast ---------- */
#toast{position:fixed;left:50%;bottom:28px;transform:translate(-50%,20px);z-index:100;opacity:0;pointer-events:none;transition:.24s ease;background:#101720;color:#fff;font-size:13px;padding:10px 16px;border-radius:10px;box-shadow:0 12px 30px -12px rgba(0,0,0,.6)}
#toast.on{opacity:1;transform:translate(-50%,0)}

/* ---------- login ---------- */
.login-wrap{min-height:100vh;display:grid;place-items:center;padding:24px}
.login{width:min(380px,92vw);background:var(--panel);border:1px solid var(--line);border-radius:18px;box-shadow:var(--shadow);padding:28px}
.login .mark{width:46px;height:46px;border-radius:13px;display:grid;place-items:center;background:linear-gradient(140deg,#2f6bff,#12b5a5);box-shadow:0 8px 20px -10px rgba(47,107,255,.8);margin-bottom:16px}
.login .mark svg{width:24px;height:24px;stroke:#fff}
.login h1{margin:0 0 4px;font-size:18px;letter-spacing:.2px}
.login p{margin:0 0 20px;color:var(--muted);font-size:13px}
.login input{width:100%;height:42px;padding:0 14px;border-radius:10px;border:1px solid var(--line);background:var(--panel-soft);color:var(--text);outline:0;font-size:15px;letter-spacing:.3em;text-align:center}
.login input:focus{border-color:var(--accent);box-shadow:0 0 0 3px color-mix(in srgb,var(--accent) 12%,transparent)}
.login .err{margin:10px 0 0;color:#e5484d;font-size:12.5px}
.login button{width:100%;height:40px;margin-top:14px;border-radius:10px;background:linear-gradient(135deg,#3b74ff,#2f6bff);color:#fff;font-weight:600;font-size:14px;box-shadow:0 8px 18px -10px rgba(47,107,255,.9)}

/* ---------- tabs ---------- */
.tabs{display:flex;gap:4px;margin-left:8px}
.tab{padding:5px 13px;border-radius:9px;font-size:13px;font-weight:550;color:var(--muted);transition:.15s}
.tab:hover{background:var(--hover);color:var(--text)}
.tab.active{background:var(--accent-soft);color:var(--accent)}
@media (max-width:720px){.tab{padding:4px 10px}.tabs{margin-left:2px}}

/* ---------- text sharing ---------- */
.composer{padding:14px 16px}
.composer textarea{width:100%;min-height:100px;resize:vertical;border:1px solid var(--line);border-radius:10px;background:var(--panel-soft);color:var(--text);padding:10px 12px;font:inherit;font-size:13.5px;line-height:1.55;outline:0}
.composer textarea:focus{border-color:var(--accent);box-shadow:0 0 0 3px color-mix(in srgb,var(--accent) 12%,transparent)}
.composer-foot{display:flex;align-items:center;gap:10px;margin-top:10px}
.composer-foot .spacer{flex:1}
.snippet{padding:12px 16px;border-bottom:1px solid var(--line-soft)}
.snippet:last-child{border-bottom:0}
.snippet:hover{background:var(--hover)}
.s-head{display:flex;align-items:center;gap:10px;color:var(--muted);font-size:11.5px;margin-bottom:6px}
.s-head .spacer{flex:1}
.s-body{white-space:pre-wrap;word-break:break-word;font-size:13.5px;line-height:1.55;max-height:260px;overflow:auto}
.snippet .act{opacity:0;transition:.15s}
.snippet:hover .act{opacity:1}
@media (max-width:720px){.snippet .act{opacity:1}}
"""#

    static let js = #"""
(function () {
  var DIR = document.body.getAttribute('data-dir') || '';
  var CAN_UPLOAD = document.body.getAttribute('data-upload') === '1';
  var CAN_DELETE = document.body.getAttribute('data-delete') === '1';

  function $(sel) { return document.querySelector(sel); }
  function el(tag, cls) { var n = document.createElement(tag); if (cls) n.className = cls; return n; }

  var toastTimer = null;
  function toast(msg) {
    var t = $('#toast');
    if (!t) return;
    t.textContent = msg;
    t.classList.add('on');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () { t.classList.remove('on'); }, 2200);
  }

  /* ---------- modal helpers ---------- */
  var modal = $('#modal');
  var resolver = null;

  function openModal(html, onOk) {
    modal.innerHTML = '';
    var box = el('div', 'dialog');
    box.innerHTML = html;
    modal.appendChild(box);
    modal.classList.add('on');
    var input = box.querySelector('input');
    if (input) { setTimeout(function () { input.focus(); input.select(); }, 30); }
    var ok = box.querySelector('[data-ok]');
    var cancel = box.querySelector('[data-cancel]');
    function close() { modal.classList.remove('on'); modal.innerHTML = ''; }
    function submit() { var v = input ? input.value : ''; close(); onOk(v); }
    if (ok) ok.addEventListener('click', submit);
    if (cancel) cancel.addEventListener('click', close);
    box.addEventListener('keydown', function (e) {
      if (e.key === 'Enter') { e.preventDefault(); submit(); }
      if (e.key === 'Escape') close();
    });
    modal.addEventListener('click', function (e) { if (e.target === modal) close(); }, { once: true });
  }

  /* ---------- filter ---------- */
  var search = $('#filter');
  if (search) {
    search.addEventListener('input', function () {
      var q = search.value.trim().toLowerCase();
      var rows = document.querySelectorAll('tbody tr');
      var shown = 0;
      rows.forEach(function (row) {
        var name = row.getAttribute('data-name') || '';
        var hit = !q || name.toLowerCase().indexOf(q) >= 0;
        row.style.display = hit ? '' : 'none';
        if (hit) shown++;
      });
      var c = $('#count');
      if (c) c.textContent = q ? shown + ' 项匹配' : rows.length + ' 个项目';
    });
  }

  /* ---------- upload ---------- */
  var queue = [];
  var inFlight = 0;
  var pending = 0;
  var reloading = false;

  function scheduleReload() {
    if (reloading) return;
    reloading = true;
    setTimeout(function () { location.reload(); }, 700);
  }

  function dockEnsure() {
    var dock = $('#dock');
    if (dock) dock.classList.add('on');
  }

  function uploadOne(file, finished) {
    var item = el('div', 'up');
    var title = el('div', 't');
    var name = el('b'); name.textContent = file.name;
    var pct = el('span'); pct.textContent = '0%';
    title.appendChild(name); title.appendChild(pct);
    var bar = el('div', 'bar');
    var fill = el('i'); bar.appendChild(fill);
    item.appendChild(title); item.appendChild(bar);
    $('#dock-list').appendChild(item);

    var url = '/api/upload?dir=' + encodeURIComponent(DIR) + '&name=' + encodeURIComponent(file.name);
    var xhr = new XMLHttpRequest();
    xhr.open('PUT', url, true);
    xhr.upload.onprogress = function (e) {
      if (!e.lengthComputable) return;
      var p = Math.round((e.loaded / e.total) * 100);
      pct.textContent = p + '%';
      fill.style.width = p + '%';
    };
    function fail(text) {
      pct.textContent = text;
      fill.style.background = '#e5484d';
      fill.style.width = '100%';
      toast('上传失败：' + file.name);
    }
    xhr.onload = function () {
      if (xhr.status >= 200 && xhr.status < 300) {
        pct.textContent = '完成';
        fill.style.width = '100%';
        setTimeout(function () { item.remove(); }, 1500);
      } else {
        fail('失败');
      }
      finished();
    };
    xhr.onerror = function () {
      fail('中断');
      finished();
    };
    xhr.send(file);
  }

  function pump() {
    while (inFlight < 2 && queue.length) {
      var file = queue.shift();
      inFlight++;
      uploadOne(file, function () {
        inFlight--;
        pending--;
        if (pending <= 0) scheduleReload();
        pump();
      });
    }
  }

  function enqueue(files) {
    if (!CAN_UPLOAD) { toast('当前未开启上传'); return; }
    if (!files || !files.length) return;
    dockEnsure();
    for (var i = 0; i < files.length; i++) {
      queue.push(files[i]);
      pending++;
    }
    pump();
  }

  /* ---------- buttons ---------- */
  var picker = $('#picker');
  var btnUpload = $('#btn-upload');
  if (btnUpload && picker) {
    btnUpload.addEventListener('click', function () { picker.click(); });
    picker.addEventListener('change', function () {
      enqueue(picker.files);
      picker.value = '';
    });
  }

  var btnMkdir = $('#btn-mkdir');
  if (btnMkdir) {
    btnMkdir.addEventListener('click', function () {
      openModal('<h3>新建文件夹</h3><p>在当前目录中创建</p><input type="text" placeholder="文件夹名称">' +
        '<div class="foot"><button class="btn" data-cancel>取消</button><button class="btn primary" data-ok>创建</button></div>',
        function (value) {
          var name = (value || '').trim();
          if (!name) return;
          fetch('/api/mkdir', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ dir: DIR, name: name })
          }).then(function (r) { return r.json(); }).then(function (res) {
            if (res.ok) location.reload(); else toast(res.error || '创建失败');
          });
        });
    });
  }

  document.addEventListener('click', function (e) {
    var del = e.target.closest('[data-del]');
    if (del) {
      var path = del.getAttribute('data-del');
      var name = del.getAttribute('data-name-text') || path;
      var isDir = del.getAttribute('data-isdir') === '1';
      openModal('<h3>删除' + (isDir ? '文件夹' : '文件') + '</h3><p>' + name.replace(/</g, '&lt;') + '</p>' +
        '<div class="foot"><button class="btn" data-cancel>取消</button><button class="btn danger" data-ok>删除</button></div>',
        function () {
          fetch('/api/delete', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ path: path })
          }).then(function (r) { return r.json(); }).then(function (res) {
            if (res.ok) location.reload(); else toast(res.error || '删除失败');
          });
        });
      return;
    }
    var copy = e.target.closest('[data-copy]');
    if (copy) {
      var text = copy.getAttribute('data-copy');
      if (navigator.clipboard) navigator.clipboard.writeText(text);
      toast('链接已复制');
    }
  });

  /* ---------- drag & drop ---------- */
  if (CAN_UPLOAD) {
    var overlay = $('#drop');
    var depth = 0;
    window.addEventListener('dragenter', function (e) {
      e.preventDefault(); depth++; if (overlay) overlay.classList.add('on');
    });
    window.addEventListener('dragover', function (e) { e.preventDefault(); });
    window.addEventListener('dragleave', function (e) {
      e.preventDefault(); depth--; if (depth <= 0 && overlay) { overlay.classList.remove('on'); depth = 0; }
    });
    window.addEventListener('drop', function (e) {
      e.preventDefault();
      depth = 0;
      if (overlay) overlay.classList.remove('on');
      var files = e.dataTransfer && e.dataTransfer.files;
      if (!files || !files.length) return;
      enqueue(files);
    });
  }
  /* ---------- text sharing ---------- */
  var textInput = $('#text-input');
  if (textInput) {
    var chars = $('#text-chars');
    textInput.addEventListener('input', function () {
      if (chars) chars.textContent = textInput.value.length + ' 字符';
    });
    textInput.addEventListener('keydown', function (e) {
      if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') { e.preventDefault(); sendText(); }
    });
    var sendBtn = $('#btn-text-send');
    if (sendBtn) sendBtn.addEventListener('click', sendText);
  }

  function sendText() {
    var input = $('#text-input');
    var btn = $('#btn-text-send');
    if (!input || !input.value.trim()) { toast('内容为空'); return; }
    if (btn) btn.disabled = true;
    fetch('/api/texts', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ content: input.value })
    }).then(function (r) { return r.json(); }).then(function (res) {
      if (res.ok) location.reload();
      else { toast(res.error || '发送失败'); if (btn) btn.disabled = false; }
    }).catch(function () {
      toast('网络错误');
      if (btn) btn.disabled = false;
    });
  }

  var textRefresh = $('#btn-text-refresh');
  if (textRefresh) textRefresh.addEventListener('click', function () { location.reload(); });

  document.addEventListener('click', function (e) {
    var tc = e.target.closest('[data-textcopy]');
    if (tc) {
      var tid = tc.getAttribute('data-textcopy');
      fetch('/api/text?id=' + encodeURIComponent(tid))
        .then(function (r) { return r.json(); })
        .then(function (res) {
          if (res.ok && navigator.clipboard) {
            navigator.clipboard.writeText(res.content);
            toast('已复制到剪贴板');
          } else {
            toast(res.error || '复制失败');
          }
        });
      return;
    }
    var tdel = e.target.closest('[data-textdel]');
    if (tdel) {
      var delId = tdel.getAttribute('data-textdel');
      openModal('<h3>删除文本</h3><p>删除后无法恢复</p>' +
        '<div class="foot"><button class="btn" data-cancel>取消</button><button class="btn danger" data-ok>删除</button></div>',
        function () {
          fetch('/api/text/delete', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ id: delId })
          }).then(function (r) { return r.json(); }).then(function (res) {
            if (res.ok) location.reload(); else toast(res.error || '删除失败');
          });
        });
    }
  });
})();
"""#
}
