import React from 'react';
import MonacoEditor from 'react-monaco-editor';
import * as monaco from 'monaco-editor';
import ReactResizeDetector from 'react-resize-detector';

class AzurehpcEditorView extends React.Component {
    editor = null;

    editorDidMount = (editor) => {
        this.editor = editor;
        editor.focus();
    };

    render() {
        const code = this.props.code;
        const options = {
            selectOnLineNumbers: true,
            readOnly: true
        };
        return (<ReactResizeDetector
            handleWidth
            handleHeight
            onResize={(x,y) => {
                console.log(x,y);
                if (this.editor) {
                    this.editor.layout();
                }
            }}
        >
            <MonacoEditor
                language="json"
                theme="vs"
                value={code}
                options={options}
                editorDidMount={this.editorDidMount}
            />
        </ReactResizeDetector>
        );
    }
}

export default AzurehpcEditorView;