(eval-when-compile
  (defvar nvm-dir))

(defun should-have-env (env value)
  (should (string= (getenv env) value)))

(defun should-use-version (version)
  (should-have-env "NVM_BIN" (f-join nvm-dir version "bin"))
  (should-have-env "NVM_PATH" (f-join nvm-dir version "lib" "node"))
  (should-have-env "PATH" (concat (f-full (f-join nvm-dir version "bin")) ":/path/to/foo/bin/:/path/to/bar/bin/")))


;;;; nvm-use

(ert-deftest nvm-use-test/version-not-available ()
  (should-error
   (nvm-use "v0.10.1")))

(ert-deftest nvm-use-test/version-available-no-callback ()
  (with-sandbox
   (stub nvm--installed-versions => '("v0.10.1"))
   (nvm-use "v0.10.1")
   (should-use-version "v0.10.1")))

(ert-deftest nvm-use-test/version-available-with-callback ()
  (with-sandbox
   (stub nvm--installed-versions => '("v0.8.2" "v0.10.1"))
   (nvm-use "v0.8.2")
   (should-use-version "v0.8.2")
   (nvm-use "v0.10.1"
            (lambda ()
              (should-use-version "v0.10.1")))
   (should-use-version "v0.8.2")))

(ert-deftest nvm-use-test/version-available-with-callback-that-errors ()
  (with-sandbox
   (stub nvm--installed-versions => '("v0.8.2" "v0.10.1"))
   (nvm-use "v0.8.2")
   (should-use-version "v0.8.2")
   (should-error
    (nvm-use "v0.10.1" (lambda () (error "BooM"))))
   (should-use-version "v0.8.2")))

(ert-deftest nvm-use-test/short-version ()
  (with-sandbox
   (stub nvm--installed-versions => '("v0.10.1"))
   (nvm-use "0.10")
   (should-use-version "v0.10.1")))


;;;; nvm-use-for

(ert-deftest nvm-use-for-test/no-config ()
  (with-sandbox
   (should-error
    (nvm-use-for nvm-test/sandbox-path))))

(ert-deftest nvm-use-for-test/config-no-such-version ()
  (with-sandbox
   (write-nvmrc "v0.10.1")
   (stub nvm--installed-versions => '("v0.8.2"))
   (should-error
    (nvm-use-for nvm-test/sandbox-path))))

(ert-deftest nvm-use-for-test/config-no-callback ()
  (with-sandbox
   (write-nvmrc "v0.10.1")
   (stub nvm--installed-versions => '("v0.8.2" "v0.10.1"))
   (nvm-use-for nvm-test/sandbox-path)
   (should-use-version "v0.10.1")))

(ert-deftest nvm-use-for-test/config-callback ()
  (with-sandbox
   (write-nvmrc "v0.10.1")
   (stub nvm--installed-versions => '("v0.8.2" "v0.10.1"))
   (nvm-use "v0.8.2")
   (should-use-version "v0.8.2")
   (nvm-use-for nvm-test/sandbox-path
                (lambda ()
                  (should-use-version "v0.10.1")))
   (should-use-version "v0.8.2")))

(ert-deftest nvm-use-for-test/no-path ()
  (with-sandbox
   (write-nvmrc "v0.8.2")
   (stub nvm--installed-versions => '("v0.8.2"))
   (nvm-use-for)
   (should-use-version "v0.8.2")))

(ert-deftest nvm-use-for-test/short-version ()
  (with-sandbox
   (write-nvmrc "v0.10")
   (stub nvm--installed-versions => '("v0.8.2" "v0.10.1"))
   (nvm-use-for nvm-test/sandbox-path)
   (should-use-version "v0.10.1")))


;;;; nvm--find-exact-version-for

(ert-deftest nvm--find-exact-version-for-test ()
  (with-mock
   (stub nvm--installed-versions => '("v0.8.2" "v0.8.8" "v0.6.0" "v0.10.7" "v0.10.2"))
   (should-not (nvm--find-exact-version-for "0"))
   (should-not (nvm--find-exact-version-for "v0"))
   (should-not (nvm--find-exact-version-for "0.3"))
   (should-not (nvm--find-exact-version-for "v0.6.1"))
   (should-not (nvm--find-exact-version-for "v0.6.0.1"))
   (should-not (nvm--find-exact-version-for "merry christmas"))
   (should (string= (nvm--find-exact-version-for "v0.6.0") "v0.6.0"))
   (should (string= (nvm--find-exact-version-for "v0.8.2") "v0.8.2"))
   (should (string= (nvm--find-exact-version-for "v0.10.7") "v0.10.7"))
   (should (string= (nvm--find-exact-version-for "v0.6") "v0.6.0"))
   (should (string= (nvm--find-exact-version-for "0.8") "v0.8.8"))
   (should (string= (nvm--find-exact-version-for "v0.8") "v0.8.8"))
   (should (string= (nvm--find-exact-version-for "v0.10") "v0.10.7"))
   (should (string= (nvm--find-exact-version-for "0.10") "v0.10.7"))))