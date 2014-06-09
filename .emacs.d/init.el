;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ロードパスの設定
;;;;;;;;;;;;;;;;;;;;;;;;;
(defun add-to-load-path (&rest paths)
  (let (path)
    (dolist (path paths paths)
      (let ((default-directory
              (expand-file-name (concat user-emacs-directory path))))
        (add-to-list 'load-path default-directory)
        (if (fboundp 'normal-top-level-add-subdirs-to-load-path)
            (normal-top-level-add-subdirs-to-load-path))))))

(add-to-load-path "elisp" "conf" "elpa" "public_repos/magit"
                  "public_repos/helm" "public_repos/full-ack")

(add-to-list 'load-path "/usr/local/share/emacs/24.1/site-lisp/skk")
(load-file "/usr/share/emacs/site-lisp/ProofGeneral/generic/proof-site.el")

(add-to-list 'custom-theme-load-path "~/.emacs.d/public_repos/replace-colorthems")

;;;;;;;;;;;;;;;;;;;;;;;;;
;;; 設定時に使用する関数定義
;;;;;;;;;;;;;;;;;;;;;;;;;
(defun init-add-autoload (file list)
  ;; add autoload function from list
  (if (null list) t
    (let ((fun (car list)))
      (autoload fun file nil t)
      (init-add-autoload file (cdr list)))))

(defun init-add-fun-to-hooks (fun hooks)
  ;; add function to hooks
  (if (null hooks) t
    (let ((hook (car hooks)))
      (add-hook hook fun)
      (init-add-fun-to-hooks fun (cdr hooks)))))

(defmacro append-to-list (to lst)
  `(setq ,to (append ,lst ,to)))

;;;;;;;;;;;;;;;;;;;;;;;;;
;;; package.el の設定 (ELPA の設定)
;;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "package")
  
  (eval-after-load "package"
    '(progn
       (mapc #'(lambda (x) (add-to-list 'package-archives x)) ;package の追加
             '(("marmalade" . "http://marmalade-repo.org/packages/")
               ("melpa" . "http://melpa.milkbox.net/packages/")
               ("MELPA" . "http://melpa.milkbox.net/packages/")))))
  
  (package-initialize))

;;;;;;;;;;;;;;;;;;;;;;;;;
;;; auto-install の設定
;;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "auto-install")
  
  (eval-after-load "auto-install"
    '(progn
       (setq auto-install-directory "~/.emacs.d/elisp/"	;;インストール先を変更
             ediff-window-setup-function 'ediff-setup-windows-plain)
       (auto-install-update-emacswiki-package-name t))) ;emacswikiのパッケージを更新
  
  (init-add-autoload "auto-install"
                     '(auto-install-from-buffer
                       auto-install-from-url
                       auto-install-from-emacswiki
                       auto-install-from-gist
                       auto-install-from-library
                       auto-install-from-directory
                       auto-install-from-dired))) 

;;;;;;;;;;;;;;;;;;;;;;;;;
;;; 文字コード/ ファイル名の設定
;;;;;;;;;;;;;;;;;;;;;;;;;
(set-language-environment "Japanese")  ; emacs のロケールを日本語に
(if (eq system-type 'gnu/linux)		   ; OS によってコーディングを変える
    (prefer-coding-system 'utf-8-unix)
  (progn
    (prefer-coding-system 'sjis-dos)     ; Windows ならコーディングを sjis に
    (set-file-name-coding-system 'cp932) ; ファイル名も sjis
    (setq locale-coding-system 'cp932)))	  

;;;;;;;;;;;;;;;;;;;;;;;;;
;;; elscreen の設定 
;;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "elscreen")
  (declare-function elscreen-start "elscreen.el")
  
  (eval-after-load "elscreen"
    '(progn
       (elscreen-set-prefix-key (kbd "C-;"))
       
       (defmacro elscreen-create-automatically (ad-do-it)
         (` (if (not (elscreen-one-screen-p))
                (, ad-do-it)
              (elscreen-create)
              (elscreen-notify-screen-modification 'force-immediately)
              (elscreen-message "New screen is automatically created"))))
       
       (defadvice elscreen-next (around elscreen-create-automatically activate)
         (elscreen-create-automatically ad-do-it))
       
       (defadvice elscreen-previous (around elscreen-create-automatically activate)
         (elscreen-create-automatically ad-do-it))
       
       (defadvice elscreen-toggle (around elscreen-create-automatically activate)
         (elscreen-create-automatically ad-do-it))))
  
  (elscreen-start))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; モードラインの設定
;;;;;;;;;;;;;;;;;;;;;;;;
;;; nyan-mode
(when (locate-library "nyan-mode")
  (declare-function nyan-mode "nyan-mode.el")
  
  (eval-after-load "nyan-mode"
    '(progn
       (setq nyan-bar-length 10
             nyan-wavy-trail nil)
       (nyan-stop-animation)))
  
  (nyan-mode))

;; Mode line setup
(setq-default
 mode-line-format
 '(; Position, including warning for 80 columns
   (:propertize "%4l:" face mode-line-position-face)
   (:eval (propertize "%3c" 'face
                      (if (>= (current-column) 80)
                          'mode-line-80col-face
                        'mode-line-position-face)))
   ;; emacsclient [default -- keep?]
   mode-line-client
   " "
   ;; read-only or modified status
   (:eval
    (cond (buffer-read-only
           (propertize "RO" 'face 'mode-line-read-only-face))
          ((buffer-modified-p)
           (propertize "**" 'face 'mode-line-modified-face))
          (t "NE")))
   ;; directory and buffer/file name
   " "
   (:propertize (:eval (shorten-directory default-directory 30))
                face mode-line-folder-face)
   (:propertize "%b"
                face mode-line-filename-face)
   " "
   "["(:propertize mode-name face mode-line-mode-face)"]"
   (:propertize mode-line-process face mode-line-process-face)
   (global-mode-string global-mode-string)
   " "
   (:eval (when nyan-mode (list (nyan-create)))) "%p"
   ))

;; Helper function
(defun shorten-directory (dir max-length)
  "Show up to `max-length' characters of a directory name `dir'."
  (let ((path (reverse (split-string (abbreviate-file-name dir) "/")))
        (output ""))
    (when (and path (equal "" (car path)))
      (setq path (cdr path)))
    (while (and path (< (length output) (- max-length 4)))
      (setq output (concat (car path) "/" output))
      (setq path (cdr path)))
    (when path
      (setq output (concat ".../" output)))
    output))

;; Extra mode line faces
(make-face 'mode-line-read-only-face)
(make-face 'mode-line-modified-face)
(make-face 'mode-line-folder-face)
(make-face 'mode-line-filename-face)
(make-face 'mode-line-position-face)
(make-face 'mode-line-mode-face)
(make-face 'mode-line-minor-mode-face)
(make-face 'mode-line-process-face)
(make-face 'mode-line-80col-face)

(set-face-attribute 'mode-line nil
                    :foreground "gray60" :background "gray20"
                    :inverse-video nil
                    :box '(:line-width 2 :color "gray20" :style nil))
(set-face-attribute 'mode-line-inactive nil
                    :foreground "gray80" :background "gray40"
                    :inverse-video nil
                    :box '(:line-width 4 :color "gray40" :style nil))
(set-face-attribute 'mode-line-read-only-face nil
                    :inherit 'mode-line-face
                    :foreground "#4271ae"
                    :box '(:line-width 2 :color "#4271ae"))
(set-face-attribute 'mode-line-modified-face nil
                    :inherit 'mode-line-face
                    :foreground "#c82829"
                    :background "#ffffff"
                    :box '(:line-width 2 :color "#c82829"))
(set-face-attribute 'mode-line-folder-face nil
                    :inherit 'mode-line-face
                    :foreground "gray60")
(set-face-attribute 'mode-line-filename-face nil
                    :inherit 'mode-line-face
                    :foreground "#eab700"
                    :weight 'bold)
(set-face-attribute 'mode-line-position-face nil
                    :inherit 'mode-line-face
                    :family "Menlo" :height 100)
(set-face-attribute 'mode-line-mode-face nil
                    :inherit 'mode-line-face
                    :foreground "gray80")
(set-face-attribute 'mode-line-minor-mode-face nil
                    :inherit 'mode-line-mode-face
                    :foreground "gray60"
                    :height 110)
(set-face-attribute 'mode-line-process-face nil
                    :inherit 'mode-line-face
                    :foreground "#718c00")
(set-face-attribute 'mode-line-80col-face nil
                    :inherit 'mode-line-position-face
                    :foreground "black" :background "#eab700")

;;;;;;;;;;;;;;;;;;;;;;;;;
;;; キーバインドの設定
;;;;;;;;;;;;;;;;;;;;;;;;;
(keyboard-translate ?\C-h ?\C-?)						; C-hをBackSpaceキーに変更
(global-set-key "\C-h" nil)
(global-set-key (kbd "C-m") 'newline-and-indent)		; C-m に改行・インデントを割り当てる
(global-set-key (kbd "C-c l") 'toggle-truncate-lines)	; C-c l に折り返しを割り当てる
(global-set-key (kbd "M-l") 'goto-line)
(global-set-key (kbd "C-c i")							; C-c で init ファイルオープン
                #'(lambda () (interactive)
                   (find-file "~/.emacs.d/init.el")))
(global-set-key (kbd "C-c j") 'split-window-horizontally)
(global-set-key (kbd "C-c u") 'split-window-vertically)
(global-set-key (kbd "C-c r") 'query-replace)
(global-set-key (kbd "C-c C-r") 'query-replace-regexp)
(global-set-key (kbd "C-c C-f") 'find-function)

;;;;;;;;;;;;;;;;;;;;;;;;
;;; popwin 設定
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "popwin")
  (declare-function popwin-mode "popwin.el")
  
  (eval-after-load "popwin"
    '(progn
       (setq popwin:close-popup-window-timer-interval 0.05)

       (mapc #'(lambda (x) (add-to-list 'popwin:special-display-config x))
             '(("*Help*" :height 20 :position bottom :noselect t)
               (" *auto-async-byte-compile*" :height 12 :position bottom :noselect t)
               ("*sdic*" :height 12 :position bottom :noselect t)
               ("*Backtrace*":height 12 :position bottom :noselect t)
               ("*ack*":height 12 :position bottom)
               ("^\*helm.+\*$" :height 20 :position bottom :regexp t)
               ("^\*Org.+\*$" :height 20 :position bottom :regexp t)
               ("^\*magit.+\*$" :height 25 :position bottom :regexp t)))))
  
  (autoload 'popwin-mode "popwin" nil t)
  
  (popwin-mode 1))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; redo+ の設定
;;; http://www11.atwiki.jp/s-irie/pages/18.html
;;;;;;;;;;;;;;;;;;;;;;;;
(when (require 'redo+ nil t)
  (global-set-key (kbd "C-.") 'redo))	;redo を C-.に設定

;;;;;;;;;;;;;;;;;;;;;;;;
;;; SKK の設定
;;; http://openlab.ring.gr.jp/skk/index-j.html
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "skk")
  (declare-function skk-mode "skk.el")
  (declare-function skk-latin-mode-on "skk.el")
  
  (eval-after-load "skk"
    '(progn
       (setq default-input-method "japanese-skk" 
             skk-large-jisyo "~/.skk/SKK-JISYO.L"		;辞書ファイルの場所
             skk-kutouten-type 'en)						; 句読点を「，．」にする
       
       (skk-mode 1)										; 次のfaceを定義させるために必要
       
       (set-face-attribute 'skk-emacs-hiragana-face nil
                           :family "MigMix 2M"
                           :foreground "pink")))
  
  (when (require 'skk-autoloads nil t)
    
    (global-set-key (kbd "<muhenkan>") 'skk-mode)
    (global-set-key (kbd "<zenkaku-hankaku>") 'skk-mode)
    
    (init-add-fun-to-hooks
     #'(lambda () (skk-mode 1) (skk-latin-mode-on))
     '(find-file-hook lisp-intraction-mode-hook))))

;;;;;;;;;;;;;;;;;;;;;;;;;
;;; moccur 関連の設定
;;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "color-moccur") 

  (eval-after-load "color-moccur"
    '(progn
       (setq moccure-split-word t
             moccur-kill-moccur-buffer t
             moccur-grep-default-word-near-point t)
       
       (mapc #'(lambda (x) (add-to-list 'dmoccur-exclusion-mask x))
             ;; ディレクトリ検索するとき除外するファイル
             '("\\.DS_Store" "^#.+#$")))) 
  
  (init-add-autoload "color-moccur" '(moccur-grep-find))
  
  (global-set-key (kbd "C-c s") 'moccur-grep-find))

(when (require 'moccur-edit nil t)
  
  ;; moccur-edit-finish-edit と同時にファイルを保存する
  (defadvice moccur-edit-change-file 
    (after save-after-moccur-edit-buffer activate)
    (save-buffer)))

;;;;;;;;;;;;;;;;;;;;;;;;;
;;; wgrep の設定 (grep 検索の後に編集できる)
;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'wgrep nil t)

;;;;;;;;;;;;;;;;;;;;;;;;;
;;; undohist の設定 (undo のヒストリー確認できる)
;;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "undohist")
  (declare-function undohist-initialize "undohist.el")
  
  (eval-after-load "undohist"
    '(progn
       (setq undohist-directory "~/.undohist")
       (setq undohist-ignored-files '("COMMIT_EDITMSG"))))

  (init-add-autoload "undohist" '(undohist-initialize))
  
  (undohist-initialize))

;;;;;;;;;;;;;;;;;;;;;;;;;
;;; undo-tree (undo を樹形図で表示する elisp)
;;;;;;;;;;;;;;;;;;;;;;;;;
(when (require 'undo-tree nil t)
  (declare-function global-undo-tree-mode "undo-tree.el")
  
  (global-undo-tree-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;
;;; point-undo (ポイントの履歴を保存する)
;;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "point-undo")
  
  (init-add-autoload "point-undo" '(point-undo point-redo))
  
  (global-set-key (kbd "C-o") 'point-undo)
  (global-set-key (kbd "C-x C-o") 'point-redo))

;;;;;;;;;;;;;;;;;;;;;;;;;
;;; sequential-command の設定
;;;;;;;;;;;;;;;;;;;;;;;;;.
(when (locate-library "sequential-command-config")
  
  (init-add-autoload "sequential-command-config" '(seq-home seq-end))
  
  (global-set-key (kbd "C-a") 'seq-home)
  (global-set-key (kbd "C-e") 'seq-end))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; lispxmp の設定
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "lispxmp")

  (init-add-autoload "lispxmp" '(lispxmp))
  
  (define-key emacs-lisp-mode-map (kbd "C-c C-d") 'lispxmp)
  (define-key lisp-interaction-mode-map (kbd "C-c C-d") 'lispxmp))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; paredit の設定
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "paredit")
  
  (init-add-autoload "paredit" '(enable-paredit-mode
                                 paredit-wrap-round
                                 paredit-splice-sexp))
  
  (define-key emacs-lisp-mode-map (kbd "M-8") 'paredit-wrap-round)
  (define-key emacs-lisp-mode-map (kbd "M-9") 'paredit-splice-sexp)
  
  ;; paredit-modeが自動で起動するようにhookに追加 
  (init-add-fun-to-hooks 'enable-paredit-mode
                         '(emacs-lisp-mode-hook
                           scheme-mode-hook
                           lisp-interaction-mode-hook
                           lisp-mode-hook
                           ielm-mode-hook)))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; auto-async-byte-compile の設定
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "auto-async-byte-compile")
  
  (eval-after-load "auto-async-byte-compile"
    '(progn
       (setq auto-async-byte-compile-exclude-files-regexp "~/junk/")))
  
  (init-add-autoload "auto-async-byte-compile" '(enable-auto-async-byte-compile-mode))
  
  (init-add-fun-to-hooks 'enable-auto-async-byte-compile-mode '(emacs-lisp-mode-hook)))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; eldoc-mode の設定
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "eldoc")
  
  (eval-after-load "eldoc"
    '(progn
       (require 'eldoc-extension nil t)
       (setq eldoc-idle-delay 0.5				  ; eldocをすぐ表示
             eldoc-echo-area-use-multiline-p t))) ; 複数行にわたって表示
  
  (init-add-fun-to-hooks
   'turn-on-eldoc-mode
   '(lisp-interaction-mode-hook
     lisp-mode-hook
     ielm-mode-hook
     emacs-lisp-mode-hook)))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; lisp その他の設定
;;;;;;;;;;;;;;;;;;;;;;;;
(find-function-setup-keys)
(define-key emacs-lisp-mode-map (kbd "C-c f") 'describe-function)
(define-key emacs-lisp-mode-map (kbd "C-c v") 'describe-variable)
(set-face-foreground 'font-lock-regexp-grouping-backslash "green3")
(set-face-foreground 'font-lock-regexp-grouping-construct "green3")

;;;;;;;;;;;;;;;;;;;;;;;;
;;; open-junk-file の設定
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "open-junk-file")
  
  (init-add-autoload "open-junk-file" '(open-junk-file))
  
  (global-set-key (kbd "C-c C-j") 'open-junk-file))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; gtags の設定
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "gtags")
  (declare-function gtags-mode "gtags.el")
  (declare-function gtags-make-complete-list "gtags.el")
  
  (eval-after-load "gtats"
    '(progn
       (define-set-key gtags-mode-map (kbd "M-t") 'gtags-find-tag) ;関数定義にジャンプ
       (define-set-key gtags-mode-map (kbd "M-r") 'gtags-find-rtag) ;関数呼び出し場所にジャンプ
       (define-set-key gtags-mode-map (kbd "M-s") 'gtags-find-symbol) ;シンボル参照先にジャンプ
       (define-set-key gtags-mode-map (kbd "C-t") 'gtags-pop-stack)))

  (init-add-autoload "gtags" '(gtags-mode)))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; ctags の設定
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "ctags")
  
  (eval-after-load "ctags"
    '(progn
       (setq tags-revert-without-query t
             ctags-command "ctags -R")))

  (init-add-autoload "ctags" '(ctags-create-or-update-tags-table))
  
  (global-set-key (kbd "<f5>") 'ctags-create-or-update-tags-table)) ;tag ファイルの生成

;;;;;;;;;;;;;;;;;;;;;;;;;
;;; rst モードの設定 
;;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "rst")
  
  (add-to-list 'auto-mode-alist '("\\.rst$" . rst-mode))
  
  ;; 背景が黒い場合はこうしないと見出しが見づらい
  (setq frame-background-mode 'dark))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; フックの設定
;;;;;;;;;;;;;;;;;;;;;;;;
(add-hook 'after-save-hook
          'executable-make-buffer-file-executable-if-script-p) ;ファイルが#! から始まる場合, +x を付ける
(add-hook 'c-mode-common-hook
          #'(lambda ()
              (gtags-mode 1)				;gtags モードに入るようにする
              (gtags-make-complete-list)
              (hide-ifdef-mode)))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; auotinsert の設定
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "autoinsert")
  
  (eval-after-load "autoinsert"
    '(progn
       (auto-insert-mode 1)
       (setq auto-insert-directory "~/.emacs.d/conf/insert" ; テンプレートファイルの場所
             auto-insert-query t ; テンプレートを挿入するか聞く
             auto-insert-alist ; 拡張子とテンプレートを対応づける
             '(("\\.py$" . "py.template")
               ("\\.org$" . "org.template")))))

  (init-add-autoload "autoinsert" '(auto-insert))
  
  (add-hook 'find-file-hooks 'auto-insert))

;;;;;;;;;;;;;;;;;;;;;;;;;
;;; multi-term の設定
;;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "multi-term")
  
  (eval-after-load "multi-term"
    '(progn
       (setq multi-term-program "/bin/bash")))
  
  (defalias 'sh 'multi-term))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; バックアップファイルの設定
;;;;;;;;;;;;;;;;;;;;;;;;
(setq backup-directory-alist
      `((".*" . ,temporary-file-directory))) ; tmp フォルダにバックアップファイルを保存
(setq auto-save-file-name-transforms
      `((".*" ,temporary-file-directory t))) ; tmp フォルダにバックアップファイルを保存

;;;;;;;;;;;;;;;;;;;;;;;;
;;; Misc 雑多な設定
;;;;;;;;;;;;;;;;;;;;;;;;
(tool-bar-mode -1)                  ; ツールバーの消去
(electric-pair-mode)                ; 自動的に括弧のペアを挿入
(setq inhibit-startup-message t     ; 起動時の初期バッファーを表示させない
      frame-title-format "%f"       ; タイトルバーにファイルのフルパスを表示
      line-move-visual t            ; 論理行に対し表示行のように扱う
      case-fold-search t            ;
      completion-ignore-case t      ; 補完時に大文字小文字を区別しない
      kill-whole-line t             ; 先頭でkillしたら行を消去
      completion-ignore-case t)     ; ファイル検索時大文字小文字を区別しない
(fset 'yes-or-no-p 'y-or-n-p)       ; y
(auto-image-file-mode t)            ; バッファ内で画像ファイルを表示する

;;; バッファローカル変数のグローバル設定
(setq-default tab-width 2)          ; タブの設定
(setq-default indent-tabs-mode nil)	; タブを使用しない
(setq-default fill-column 80)       ; auto fillを80文字で設定

;;; カーソルの変更
(blink-cursor-mode 0)                   ; 点滅させない

;;;;;;;;;;;;;;;;;;;;;;;;
;;; cua-mode
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "cua-base")
  
  (eval-after-load "cua-base"
    '(progn
       (setq cua-enable-cua-keys nil)	; cuaのキーバインドを禁止
       
       ;; coqでC-RETを使用しているため，以下のようにキーバインドを定義する
       (define-key global-map (kbd "C-x SPC") 'cua-set-rectangle-mark)
       (define-key global-map (kbd "C-x C-SPC") 'cua-set-rectangle-mark)))

  (cua-mode 1))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; 現在行のハイライトの設定
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "crosshairs")
  (declare-function crosshairs-mode "crosshairs.el")
  
  (eval-after-load "crosshairs"
    '(progn
       (setq col-highlight-vline-face-flag t) ;行と列の色を一緒にするため
       (set-face-attribute 'hl-line nil
                           :background "Gray15"
                           :weight 'bold)
       (set-face-attribute 'col-highlight nil
                           :background "Gray15")))

  (crosshairs-mode))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; 括弧のハイライトの設定
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "paren")
  
  (eval-after-load "paren"
    '(progn
       (setq show-paren-delay 0 ;括弧のハイライトを表示するまでの時間
             show-paren-style 'expression) 				;括弧の中もハイライト       
       (set-face-background 'show-paren-match-face nil) ;バックグランドフェイスを消す
       (set-face-underline 'show-paren-match-face "green"))) ;下線の色をつける
  
  (show-paren-mode t))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; カラーテーマの追加
;;; http://code.google.com/p/gnuemacscolorthemetest/
;;;;;;;;;;;;;;;;;;;;;;;;
(when (load-theme 'dark-laptop t t)
  (enable-theme 'dark-laptop)

  (set-face-attribute 'default nil
                      :family "MigMix 2M"
                      :height 110)

  (set-face-attribute 'font-lock-comment-face nil
                      :foreground "turquoise")
  
  (set-face-foreground 'font-lock-builtin-face "magenta"))


;;;;;;;;;;;;;;;;;;;;;;;;
;;; tuareg-mode (ocaml 関係)
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "tuareg")
  
  (eval-after-load "tuareg"
    '(progn
       (setenv "PATH" (concat '"~/.opam/4.01.0/bin:" (getenv "PATH")))
       
       (setq tuareg-library-path "/home/ym/.opam/4.01.0/lib/ocaml"
             ocamlspot-command "ocamlspot"
             tuareg-interactive-program "ocaml")

       ;; インデントの設定

       (setq tuareg-leading-star-in-doc t
             tuareg-lazy-= t
             tuareg-lazy-paren t
             tuareg-in-indent 0
             tuareg-with-indent 0
             tuareg-electric-indent nil)
       
       (auto-fill-mode 1)
       (flymake-mode-on)
       
       (if (featurep 'sym-lock)   
           (setq sym-lock-mouse-face-enabled nil))
       
       (when (locate-library "ocamlspot")

         (eval-after-load "ocamlspot"
           '(progn
              (if (eq major-mode 'tuareg-mode)
                  (ocamlspot-type))))
         
         (init-add-autoload "ocamlspot"
                            '(ocamlspot-query
                              ocamlspot-query-interface
                              ocamlspot-query-uses
                              ocamlspot-type
                              ocamlspot-xtype
                              ocamlspot-type-and-copy
                              ocamlspot-expand
                              ocamlspot-use
                              caml-types-show-type
                              caml-types-show-type
                              ocamlspot-pop-jump-stack
                              toggle-ocamlspot-type-timer))

         (define-key tuareg-mode-map (kbd "C-c ;") 'ocamlspot-query)
         (define-key tuareg-mode-map (kbd "C-c :") 'ocamlspot-query-interface)
         (define-key tuareg-mode-map (kbd "C-c '") 'ocamlspot-query-uses)
         (define-key tuareg-mode-map (kbd "C-c C-t") 'ocamlspot-type)
         (define-key tuareg-mode-map (kbd "C-c C-i") 'ocamlspot-xtype)
         (define-key tuareg-mode-map (kbd "C-c C-y") 'ocamlspot-type-and-copy)
         (define-key tuareg-mode-map (kbd "C-c x") 'ocamlspot-expand)
         (define-key tuareg-mode-map (kbd "C-c C-u") 'ocamlspot-use)
         (define-key tuareg-mode-map (kbd "C-c t") 'caml-types-show-type)
         (define-key tuareg-mode-map (kbd "C-c p") 'ocamlspot-pop-jump-stack)
         (define-key tuareg-mode-map (kbd "C-c C-t") 'toggle-ocamlspot-type-timer))
       
       (define-key tuareg-mode-map (kbd "C-:") 'tuareg-browse-library)
       (define-key tuareg-mode-map (kbd "C-c i") nil)
       
       (define-key tuareg-interactive-mode-map (kbd "C-:")
         'tuareg-browse-library)

       ;; faceの設定
       (set-face-attribute 'tuareg-font-lock-governing-face nil
                           :foreground "orange"
                           :weight 'bold)
       
       (defface tuareg-font-lock-module-face
         '((t (:foreground "SeaGreen1"))) nil)
       
       (defvar tuareg-font-lock-module-face
         'tuareg-font-lock-module-face)
       
       (defface tuareg-font-lock-variant-face
         '((t (:foreground "light steel blue"))) nil)
       (defvar tuareg-font-lock-variant-face
         'tuareg-font-lock-variant-face)

       (defface tuareg-font-lock-identifier-face
         '((t (:foreground "white"))) nil)
       (defvar tuareg-font-lock-ident2ifier-face
         'tuareg-font-lock-identifier-face)
       
       ;; 以下のフォントロックを定義すると重くなるので定義しない
       ;; (font-lock-add-keywords 'tuareg-mode
       ;;                         '(("\\<open[ \t\n]+\\([[:upper:]][_[:alnum:]]*\\)"
       ;;                            1 'tuareg-font-lock-module-face)
       ;;                           ("\\<\\([[:upper:]][_[:alnum:]]*\\)[ \t\n]*\\.[ \t\n]*[_[:alnum:]]+\\>"
       ;;                            1 'tuareg-font-lock-module-face)
       ;;                           ("\\<module[ \n\t]*[_[:alnum:]]+[ \n\t]+=[ \n\t]*\\([[:upper:]][_[:alnum:]]+\\)\\>"
       ;;                            1 'tuareg-font-lock-module-face))
       ;;                         )
       
       ;; (font-lock-add-keywords 'tuareg-mode
       ;;                         '(("\\<[[:upper:]][_[:alnum:]]*\\>"
       ;;                            0 'tuareg-font-lock-variant-face keep nil)
       ;;                           ("\\<[_[:alnum:]-']+\\>"
       ;;                            0 'tuareg-font-lock-identifier-face keep nil)
       ;;                           ) t)
       ))
  
  (autoload 'tuareg-mode "tuareg" "Major mode for editing Caml code" t)
  (autoload 'camldebug "camldebug" "Run the Caml debugger" t)
  
  (add-to-list 'auto-mode-alist '("\\.ml[iylp]?$" . tuareg-mode))
  
  (add-hook 'tuareg-mode-hook
            (lambda ()
              (set (make-local-variable 'compile-command) "omake"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; flycheck
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "flycheck")
  
  (eval-after-load "flycheck"
    '(progn
       (defvar omake-program-arguments "-P -w --verbose")
       (flycheck-define-checker ocaml-checker
         "flychecker for ocaml"
         :command ("/usr/bin/omake" "--output-only-errors" "-k" "-c"  "-w" "--verbose")
         :error-patterns
         ((error line-start "File \"" (file-name) "\", line "
                 line ", " (minimal-match (one-or-more not-newline)) ":\n" (message) line-end))
         :modes (tuareg-mode))
       
       (add-to-list 'flycheck-checkers 'ocaml-checker)
       (setq flycheck-display-errors-function #'flycheck-pos-tip-error-messages
             flycheck-pos-tip-timeout 10)
       
       (add-hook 'flycheck-mode-hook 'flycheck-color-mode-line-mode)))
  
  (add-hook 'after-init-hook #'global-flycheck-mode))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; org-mode 関係
;;; http://d.hatena.ne.jp/rubikitch/20090121/1232468026
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "org")
  (declare-function org-present-big "org-present.el")
  (declare-function org-present-small "org-present.el")
  (declare-function org-remove-inline-images "org.el")
  (declare-function org-display-inline-images "org.ell")
  
  (eval-after-load "org"
    '(progn
       (setq org-directory "~/Dropbox/Org/"
             org-default-notes-file (concat org-directory "agenda.org") ; ディレクトリの設定
             org-startup-truncated nil ; 表示を打ち切らない
             org-export-htmlize-output-type 'css ; HTML出力したときコードハイライトcssを分離する
             org-return-follows-link t
             org-use-fast-todo-selection t
             org-display-custom-times "<%Y-%m-%d %H:%M:%S>" ; 日付けの設定
             org-time-stamp-custom-formats "<%Y-%m-%d %H:%M:%S>") ; 日付けの設定
       
       ;; org-babelの設定
       (org-babel-do-load-languages
        'org-babel-load-languages
        '((python . t)
          (ocaml . t)
          (haskell . t)
          (sh .t)))
       
       (setq org-todo-keywords
             '((sequence "TODO (t)" "STARTED (s)" "WAITING (w)" "|" "DONE (x)" "CANCEL (c)")))))

  (add-to-list 'auto-mode-alist '("\\.org$" . org-mode))
  
  (add-hook 'org-mode-hook
            (lambda ()
              (auto-fill-mode 1)))
  
  (add-hook 'org-present-mode-hook
            (lambda ()
              (org-present-big)
              (setq org-present-text-scale 4)
              (org-display-inline-images)))
  
  (add-hook 'org-present-mode-quit-hook
            (lambda ()
              (org-present-small)
              (org-remove-inline-images))))

(when (locate-library "org-capture")
  
  (eval-after-load "org-capture"
    '(progn
       (setq org-capture-templates
             '(("t" "Task" entry (file+headline nil "Inbox")
                "* TODO  %?\n %T\n %a\n %i\n")
               ("m" "Memo" entry (file+headline nil "Memo")
                "* %?\n %T\n %a\n %i\n")
               ("b" "Bug" entry (file+headline nil "Inbox")
                "* TODO %?   :bug:\n  %T\n %a\n %i\n")
               ("i" "Idea" entry (file+headline nil "Idea")
                "* %?\n %U\n %i\n %a\n %i\n")))))

  (global-set-key (kbd "C-c m") 'org-capture))

;;;;;;;;;;;;;;;;;;;;
;;; scheme
;;;;;;;;;;;;;;;;;;;;
(when (locate-library "cmuscheme")

  (eval-after-load "cmuscheme"
    '(progn
       (setq scheme-program-name "/usr/bin/env gosh")))
  
  (init-add-autoload "cmuscheme" '(run-scheme)))

;;;;;;;;;;;;;;;;;;;;;;
;;;  haskell
;;;;;;;;;;;;;;;;;;;;;;
(when (require 'ob-haskell nil t))
(add-hook 'haskell-mode-hook 'turn-on-haskell-indentation)

;;;;;;;;;;;;;;;;;;;;;;;;
;;; foreign-regexp 関係
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "foreign-regexp")
  
  (eval-after-load "foreign-regexp"
    '(progn
       (setq foreign-regexp/regexp-type 'perl ; perlの正規表現を使用
             reb-re-syntax 'foreign-regexp ; Rebuilderでperlを使用する
             ))) 
  
  (autoload 'foreign-regexp/query-replace "foreign-regexp" nil t)
  
  (global-set-key (kbd "M-%") 'foreign-regexp/query-replace))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; yasnippet 関係
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "yasnippet")
  (declare-function yas-global-mode "yasnippet.el")
  
  (eval-after-load "yasnippet"
    '(progn
       (setq yas-snippet-dirs '("~/.emacs.d/conf/snippets"))
       (define-key yas-minor-mode-map (kbd "C-x i n") 'yas-new-snippet) ;add new snippet
       (define-key yas-minor-mode-map (kbd "C-x i i") 'yas-insert-snippet) ; insert snippet
       (define-key yas-minor-mode-map (kbd "C-x i v") 'yas-visit-snippet-file) ;visit snippet file
       (define-key yas-minor-mode-map (kbd "TAB") 'yas-next-field)
       (define-key yas-minor-mode-map (kbd "<tab>") nil)
       (define-key yas-minor-mode-map (kbd "TAB") nil)
       (define-key yas-minor-mode-map (kbd "C-i") nil)))
  
  (yas-global-mode 1))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; dired 関係
;;;;;;;;;;;;;;;;;;;;;;;;
(eval-after-load "dired"
  '(progn
     (define-key dired-mode-map (kbd "C-t") 'ace-window)))

(require 'dired-x nil t)
  
;;;;;;;;;;;;;;;;;;;;;;;;
;;; tempbuf 関係
;;;;;;;;;;;;;;;;;;;;;;;;
(when (require 'tempbuf nil t)
  (mapc #'(lambda (hook) (add-hook hook 'turn-on-tempbuf-mode))
        '(find-file-hook				; 自動的に消すバッファのメジャーモード
          dired-mode-hook
          compilation-mode-hook
          completion-list-mode-hook
          fundamental-mode-hook
          text-mode-hook
          special-mode-hook
          help-mode-hook
          magit-process-mode-hook
          helm-mode-hook
          helm-describe-mode-hook)))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; text-adjust 関係
;;;;;;;;;;;;;;;;;;;;;;;;
;;(when (require 'text-adjust nil t)
;;  (setq text-adjust-rule-space
;;  '((("\\cj" "" "[[0-9a-zA-Z+]")   " ")
;;    (("[]/!?0-9a-zA-Z+]" "" "\\cj") " ")))
;;  (add-hook 'before-save-hook 'text-adjust-buffer))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; bm 関係
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "bm")

  (eval-after-load "bm"
    '(progn
       (setq bm-buffer-persistence nil
             bm-restore-repository-on-load t)))

  (global-set-key (kbd "M-p") 'bm-toggle)
  (global-set-key (kbd "M-[") 'bm-previous)
  (global-set-key (kbd "M-]") 'bm-next)

  (init-add-autoload "bm" '(bm-buffer-restore bm-buffer-save))
  
  (add-hook 'find-file-hook 'bm-buffer-restore)
  (add-hook 'kill-buffer-hook 'bm-buffer-save)
  (add-hook 'after-save-hook 'bm-buffer-save)
  (add-hook 'after-revert-hook 'bm-buffer-save)
  (add-hook 'vc-before-checkin-hook 'bm-buffer-save))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; view 関係
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "viewer")
  (declare-function viewer-stay-in-setup "viewer.el")
  
  (eval-after-load "viewer"
    '(progn
       (setq viewer-modeline-color-unwritable "tomato"
             viewer-modeline-color-view "orange")
       (viewer-change-modeline-color-setup)
       (add-hook 'view-mode-hook
                 '(lambda ()
                    (define-key view-mode-map (kbd "m") 'bm-toggle)
                    (define-key view-mode-map (kbd "[") 'bm-previous)
                    (define-key view-mode-map (kbd "]") 'bm-next)))))
  
  (setq view-read-only t)
  
  (init-add-autoload "viewer" '(viewer-stay-in-setup))
  
  (viewer-stay-in-setup))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; usage-memo 関係
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "usage-memo")
  (declare-function umemo-initialize "usage-memo.el")
  
  (eval-after-load "usage-memo"
    '(progn
       (setq umemo-base-directory "~/.emacs.d/umemo")))

  (init-add-autoload "usage-memo" '(umemo-initialize))
  
  (umemo-initialize))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; summarye
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "summarye")
  
  (eval-after-load "summarye"
    '(progn
       (add-to-list 'se/mode-delimiter-alist
                    ;; ocaml
                    '(tuareg-mode "^\\(let[ \t]+\\(rec[ \t]\\)?[_[:alpha:]][_[:alnum:]]*\\)"))))

  (autoload 'se/make-summary-buffer "summarye" nil t)

  
  (defalias 'summary 'se/make-summary-buffer)) ; summaryで関数の一覧を表示させる

;;;;;;;;;;;;;;;;;;;;;;;;
;;; ipa
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "ipa")
  (require 'ipa nil t))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; proofgeneral
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "proof-site")
  (declare-function holes-mode "proof-site.el")
  
  (eval-after-load "proof-site"
    '(progn 
       (setq  proof-splash-enable nil		; 起動時のバッファを表示しない
              
              coq-prog-args
              '("-emacs-U" "-I" "~/memo/class/cpdt/src")
              
              coq-user-commands-db
              '(("Arguments" "args" "Arguments @{id} [ @{_} ]" nil "Arguments")
                ("Restart" "restart" "Restart" nil "Restart")
                ("Reset" "reset" "Reset" nil "Reset")
                ("Undo" "undo" "Undo" nil "Undo"))

              coq-user-reserved-db
              '("eqn" "goal")

              coq-user-tacticals-db
              '(("Case" "case" "Case #" t "Case")
                ("SCase" "scase" "SCase #" t "SCase")
                ("SSCase" "sscase" "SSCase #" t "SSCase")
                ("SSSCase" "ssscase" "SSSCase #" t "SSSCase")
                ("SSSSCase" "sssscase" "SSSSCase #" t "SSSSCase")
                ("SSSSSCase" "sssssscase" "SSSSSCase #" t "SSSSSSCase")
                ("Case_aux" "case_aux" "Case_aux # #" t "Case_aux")
                ("cases" "cases" "_cases # #" t "[a-z_]+_cases"))
              
              coq-user-tactics-db
              '(("remember as" "rm" "remember # as #" t "remember")
                ("info_auto" "ia" "info_auto" t "info_auto")
                ("f_equal" "feq" "f_equal" t "f_equal")
                ("introv" "introv" "introv" t "introv")
                ("inverts" "inverts" "inverts" t "inverts")
                ("splits" "splits" "splits" t "splits")
                ("branch" "branch" "branch #" t "branch")
                ("false" "false" "false" t "false")
                ("tryfalse" "tryfalse" "tryfalse" t "tryfalse")
                ("gen" "gen" "gen" t "gen")
                ("sort" "sort" "sort" t "sort")
                ("elimtyp" "elimtype" "elimtype" t "elimtype")))))

  
  ;; マイナーモードのholes-modeを有効にしない
  (add-hook 'coq-mode-hook (lambda ()
                             (holes-mode -1)
                             (set-face-attribute 'proof-locked-face nil
                                                 :background "gray12"))))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; sr-speedbar(emacs wiki から install の事)
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "sr-speedbar")
  
  (global-set-key (kbd "s-s") 'sr-speedbar-toggle))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; FULL Ack
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "full-ack")
  
  (eval-after-load "full-ack"
    ;; coq-mode で ack を行う場合は.v を使用する
    '(progn
       (add-to-list 'ack-mode-type-alist '(coq-mode "coq"))
       (add-to-list 'ack-mode-extension-alist '(coq-mode "v"))))
  
  (init-add-autoload "full-ack" '(ack-same ack ack-find-same-file ack-find-file)))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; helm
;;;;;;;;;;;;;;;;;;;;;;;;
(when (require 'helm-config nil t)
  (declare-function helm-mode "helm.el")

  (eval-after-load "helm-files"
    '(progn
       (setq helm-ff-skip-boring-files t)
       
       (append-to-list helm-boring-file-regexp-list
                       '("\\.omc$" "\\.o$" "\\.cmx$" "\\.cmi$"))
       
       (define-key helm-find-files-map (kbd "C-h")
         'delete-backward-char)
       (define-key helm-find-files-map (kbd "TAB")
         'helm-execute-persistent-action)
       (define-key helm-find-files-map (kbd "C-RET")
         'helm-select-action)
       (define-key helm-read-file-map (kbd "TAB")
         'helm-execute-persistent-action)
       
       (defadvice helm-ff-transform-fname-for-completion
         (around my-transform activate)
         "Transform the pattern to reflect my intention"
         (let* ((pattern (ad-get-arg 0))
                (input-pattern (file-name-nondirectory pattern))
                (dirname (file-name-directory pattern)))
           (setq input-pattern (replace-regexp-in-string "\\." "\\\\." input-pattern))
           (setq ad-return-value
                 (concat dirname
                         (if (string-match "^\\^" input-pattern)
                             ;; '^' is a pattern for basename
                             ;; and not required because the directory name is prepended
                             (substring input-pattern 1)
                           (concat ".*" input-pattern))))))))
  
  (eval-after-load "helm"
    '(progn
       (define-key helm-map (kbd "C-h")
         'delete-backward-char)
       
       ;; Emulate `kill-line' in helm minibuffer
       (setq helm-delete-minibuffer-contents-from-point t)
       (defadvice helm-delete-minibuffer-contents (before helm-emulate-kill-line activate)
         "Emulate `kill-line' in helm minibuffer"
         (kill-new (buffer-substring (point) (field-end))))
       ))
    
  (eval-after-load "helm-buffers"
    '(progn
       (defun helm-buffers-list-pattern-transformer (pattern)
         (if (equal pattern "")
             pattern
           ;; Escape '.' to match '.' instead of an arbitrary character
           (setq pattern (replace-regexp-in-string "\\." "\\\\." pattern))
           (let ((first-char (substring pattern 0 1)))
             (cond ((equal first-char "*")
                    (concat " " pattern))
                   ((equal first-char "=")
                    (concat "*" (substring pattern 1)))
                   (t
                    pattern)))))
       (add-to-list 'helm-source-buffers-list
                    '(pattern-transformer
                      helm-buffers-list-pattern-transformer))))

  (helm-mode 1)
  
  (global-set-key (kbd "C-c h")   'helm-mini)
  (global-set-key (kbd "M-x")     'helm-M-x)
  (global-set-key (kbd "C-x C-f") 'helm-find-files)
  (global-set-key (kbd "C-x C-r") 'helm-recentf)
  (global-set-key (kbd "M-y")     'helm-show-kill-ring)
  (global-set-key (kbd "M-i")     'helm-imenu)
  (global-set-key (kbd "C-x b")   'helm-buffers-list))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; magit
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "magit")
  
  (init-add-autoload "magit" '(magit-status)))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; uniquify
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "uniquify")
  
  (eval-after-load "uniquify"
      '(setq uniquify-buffer-name-style 'post-forward-angle-brackets))
  
  (require 'uniquify))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; markdown-mode
;;;;;;;;;;;;;;;;;;;;;;;;
(add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-mode))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; electric-case
;;;;;;;;;;;;;;;;;;;;;;;;
(when (require 'electric-case nil t)
  (declare-function electric-case-mode "electric-case.el")

  (eval-after-load "electric-case"
    '(progn
       (setq electric-case-pending-overlay 'highlight)))
  
  (defun electric-case-ocaml-init ()
    
    (electric-case-mode 1)
    (setq electric-case-max-iteraction 2)

    (setq electric-case-criteria
          (lambda (b e)
            (let ((prop (text-properties-at b)))
              (cond ((member 'font-lock-function-name-face prop) 'snake)
                    ((member 'font-lock-variable-name-fae prop) 'snake)
                    ;((member 'tuareg-font-lock-identifier-face prop) 'snake)
                    ((member 'default prop) 'snake)
                    (t nil))))))
  
  (add-hook 'tuareg-mode-hook 'electric-case-ocaml-init))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; ace jump
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "ace-jump-mode")

  (eval-after-load "ace-jump-mode"
    '(ace-jump-mode-enable-mark-sync))
  
  (init-add-autoload "ace-jump-mode"
                     '(ace-jump-mode
                       ace-jump-mode-pop-mark))
  
  (global-set-key (kbd "C-@") 'ace-jump-mode)

  (when (locate-library "ace-window")
    
    (eval-after-load "ace-window"
        '(progn
           (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))))
    
    (init-add-autoload "ace-window" '(ace-window))
    
    (global-set-key (kbd "C-t") 'ace-window)))

;;;;;;;;;;;;;;;;;;;;;;;;
;;; yagist
;;;;;;;;;;;;;;;;;;;;;;;;
(when (locate-library "yagist")
  
  (eval-after-load "yasgist"
    '(progn
       (setq yagist-github-token "******************************")))
  
  (init-add-autoload "yagist" '(yagist-list yagist-buffer-private)))
