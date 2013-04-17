(use yaml test srfi-1)

(test-begin "yaml")

(define (yaml-exp yaml)
  (yaml-parse yaml
              (lambda (enc seed) (append seed (list (list 'stream-start enc))))
              (lambda (seed) (append seed (list (list 'stream-end))))
              (lambda (version tags seed) (append seed (list (list 'document-start version tags))))
              (lambda (implicit? seed) (append seed (list (list 'document-end implicit?))))
              (lambda (alias seed) (append seed (list (list 'alias alias))))
              (lambda (value anchor tag plain quoted style seed)
                (append seed (list
                               (list 'scalar value anchor tag plain quoted style)
                               )))
              (lambda (anchor tag implicit style seed)
                (append seed (list (list 'sequence-start
                                         anchor
                                         tag
                                         implicit
                                         style))))
              (lambda (seed) (append seed (list (list 'sequence-end))))
              (lambda (anchor tag implicit style seed)
                (append seed (list (list 'mapping-start
                                         anchor
                                         tag
                                         implicit
                                         style))))
              (lambda (seed) (append seed (list (list 'mapping-end))))
              '()))

(define (find-event event-name events)
  (find (lambda (event) (eq? event-name (car event))) events))

(test-group "stream"
  (test "start" 'stream-start (caar (yaml-exp "--- foo"))))

(test-group "document-start"
  (test "version" (list 'document-start '(1 1) '())
                    (find-event 'document-start
                          (yaml-exp "%YAML 1.1\n--- foo")))
  (test "no version" (list 'document-start '() '())
                    (find-event 'document-start
                          (yaml-exp "--- foo")))
  (test "tags" (list 'document-start '() (list (cons "!" "tag:tenderlovemaking.com,2009:")))
                    (find-event 'document-start
                          (yaml-exp "%TAG ! tag:tenderlovemaking.com,2009:\n--- foo")))
)

(test-group "document-end"
  (test "implicit" '(document-end #t)
                    (find-event 'document-end (yaml-exp "--- foo")))
  (test "explicit" '(document-end #f)
                    (find-event 'document-end (yaml-exp "--- foo\n...")))
)

(test-group "alias"
  (test "A" '(alias "A") (find-event 'alias (yaml-exp "---\n- &A foo\n- *A"))))

(test-group "scalar"
  (test "plain" '(scalar "foo" #f #f #t #f 1)
                (find-event 'scalar (yaml-exp "--- foo")))
  (test "quoted" '(scalar "foo" #f #f #f #t 2)
                (find-event 'scalar (yaml-exp "--- 'foo'")))
  (test "tag" '(scalar "foo" #f "!str" #f #f 1)
                (find-event 'scalar (yaml-exp "--- !str foo")))
  (test "alias" '(scalar "foo" "A" #f #t #f 1)
                (find-event 'scalar (yaml-exp "--- &A foo")))
)

(test-group "sequence-start"
  (test "start" '(sequence-start #f #f #t 1)
                (find-event 'sequence-start (yaml-exp "---\n- foo")))
  (test "tag" '(sequence-start "tag:yaml.org,2002:seq" #f #f 2)
                (find-event 'sequence-start (yaml-exp "!!seq [ 'foo' ]")))
  (test "anchor" '(sequence-start "1" #f #t 1)
                (find-event 'sequence-start (yaml-exp "--- &1\n- 1\n")))
  (test "style" '(sequence-start #f #f #t 2)
                (find-event 'sequence-start (yaml-exp "[ 'foo' ]")))
)

(test-group "sequence-end"
  (test "end" '(sequence-end)
                (find-event 'sequence-end (yaml-exp "[ 'foo' ]")))
)

(test-group "mapping-start"
  (test "start" '(mapping-start #f #f #t 1)
                (find-event 'mapping-start (yaml-exp "---\nfoo: bar")))
  (test "tag" '(mapping-start "tag:yaml.org,2002:map" #f #f 2)
                (find-event 'mapping-start (yaml-exp "!!map { foo: bar }")))
  (test "anchor" '(mapping-start "A" #f #t 2)
                (find-event 'mapping-start (yaml-exp "--- &A { foo: bar }")))
  (test "style" '(mapping-start #f #f #t 2)
                (find-event 'mapping-start (yaml-exp "{ foo: bar }")))
)

(test-group "mapping-end"
  (test "end" '(mapping-end)
                (find-event 'mapping-end (yaml-exp "{ foo: bar }")))
)

(test-end)
(test-exit)
