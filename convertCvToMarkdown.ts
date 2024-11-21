import * as fs from 'fs';
import * as yaml from 'js-yaml';
//import markdownPdf from 'markdown-pdf';
import * as docx from 'docx';
import { Document, Packer, Paragraph, TextRun } from 'docx';

interface ResumeItem {
  year: string;
  role: string;
  company: string;
  sentences: string[];
  skills: string[];
  bullets: string[];
}

interface Contact {
  label: string;
  type: string;
  link: string
}

interface Resume {
  name: string;
  title: string;
  icon: string;
  items: ResumeItem[];
  experiences: string[];
  contacts_form: Contact[];
}

function convertCvToMarkdown(inputFile: string, outputFile: string) {
  const fileContents = fs.readFileSync(inputFile, 'utf8');
  const data: Resume = yaml.load(fileContents) as Resume;

  let markdownContent = `# ${data.name}\n\n`;

  if (data.contacts_form && data.contacts_form.length > 0) {
    markdownContent += `## Contacts\n\n`;
    data.contacts_form.forEach((contact, index) => {
      switch (contact.type) {
        case 'link':
          markdownContent += `[${contact.label}](${contact.link})`;
          break;
        case 'email':
          markdownContent += `[${contact.label}](mailto:${contact.link})`;
          break;
        case 'phone':
          markdownContent += `${contact.label}`;
          break;
      }
      if (index < data.contacts_form.length - 1) {
        markdownContent += ' - ';
      }
    });
    markdownContent += '\n\n'; // Add a new line after all contacts are processed
  }

  markdownContent += `## Experience\n\n`;

  data.experiences.forEach(experiance => {
    markdownContent += `${experiance}\n\n`;
  });

  data.items.forEach(item => {
    markdownContent += `### ${item.company}\n`;
    markdownContent += `#### ${item.role} - ${item.year}\n\n`;
    markdownContent += `\n\n`;

    if (item.bullets && item.bullets.length > 0) {
      item.bullets.forEach(bullet => {
        markdownContent += `- ${bullet}\n\n`;
      })
    }

    if (item.sentences && item.sentences.length > 0) {
      item.sentences.forEach(sentence => {
        markdownContent += `${sentence}\n\n`;
      });
    }



    //item.bullets.forEach(bullet => {
    //  markdownContent += `- ${bullet}\n\n`;
    //})

    markdownContent += `\n\n`;
  })
/*
  data.items.forEach(item => {
    markdownContent += `### ${item.company}\n`;
    markdownContent += `#### ${item.role} - ${item.year}\n\n`;
    if (item.skills && item.bullets.length > 0) {
      markdownContent += `- ${item.bullets.join('\n- ')}\n\n`;
    }
    markdownContent += `${item.text}\n\n`;
    if (item.skills && item.skills.length > 0) {
      markdownContent += `${item.skills.join('- ')}`;
    }
    markdownContent += `\n\n`;
  });
  */

  fs.writeFileSync(outputFile, markdownContent);

  // Convert markdown to PDF
  //markdownPdf().from(outputFile).to(outputFile.replace('.md', '.pdf'), () => {
  //  console.log('PDF file created');
  //});
  
/*
  // Convert markdown to Word
  const doc = new Document({
    sections: []
  });
  const paragraphs = markdownContent.split('\n').map(line => new Paragraph(line));
  doc.sections.push({ children: paragraphs });

  Packer.toBuffer(doc).then(buffer => {
    fs.writeFileSync(outputFile.replace('.md', '.docx'), buffer);
    console.log('Word file created');
  });*/
}

convertCvToMarkdown('_data/cv.yml', 'cv.md');
