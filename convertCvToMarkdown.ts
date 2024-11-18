import * as fs from 'fs';
import * as yaml from 'js-yaml';
import * as markdownPdf from 'markdown-pdf';
import * as docx from 'docx';
import { Document, Packer, Paragraph, TextRun } from 'docx';

interface ResumeItem {
  year: string;
  role: string;
  company: string;
  text: string;
  skills: string[];
}

interface Resume {
  title: string;
  experience: {
    title: string;
    icon: string;
    items: ResumeItem[];
  };
}

function convertCvToMarkdown(inputFile: string, outputFile: string) {
  const fileContents = fs.readFileSync(inputFile, 'utf8');
  const data: Resume = yaml.load(fileContents) as Resume;

  let markdownContent = `# ${data.title}\n\n`;

  data.experience.items.forEach(item => {
    markdownContent += `### ${item.company}\n`;
    markdownContent += `${item.role} - ${item.year}\n\n`;
    markdownContent += `${item.text}\n\n`;
    if (item.skills && item.skills.length > 0) {
      markdownContent += `- ${item.skills.join('\n- ')}\n\n`;
    }
  });

  fs.writeFileSync(outputFile, markdownContent);

  // Convert markdown to PDF
  markdownPdf().from(outputFile).to(outputFile.replace('.md', '.pdf'), () => {
    console.log('PDF file created');
  });

  // Convert markdown to Word
  const doc = new Document();
  const paragraphs = markdownContent.split('\n').map(line => new Paragraph(line));
  doc.addSection({ children: paragraphs });

  Packer.toBuffer(doc).then(buffer => {
    fs.writeFileSync(outputFile.replace('.md', '.docx'), buffer);
    console.log('Word file created');
  });
}

convertCvToMarkdown('_data/content.yml', 'cv.md');
